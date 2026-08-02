pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import IslandBackend

// Nucleus island — a clean-room surface built directly from the React reference
// build (`src/components/island`). Everything here is derived from that one
// source of truth:
//
//   * geometry comes from the SPECS table in IslandTokens
//   * the shape is a single black capsule, radius = min(height / 2, 32)
//   * width / height ride one spring (stiffness 360, damping 30 -> 3.6 / 0.42)
//   * content never cross-fades: it leaves, the shape morphs, the new content
//     slides up (IslandContentReveal)
//
// No legacy island state, swipe pages, overview or notch geometry is involved:
// this window owns only the capsule.
PanelWindow {
    id: root

    required property var screenObject
    property var shellRootController: null
    property var captureController: null
    property var clipboard: null
    property var notifications: null
    property var workspaces: null

    readonly property var userConfig: UserConfig

    // --- Fonts --------------------------------------------------------------
    readonly property string textFontFamily: userConfig.textFontFamily
    readonly property string heroFontFamily: userConfig.heroFontFamily
    readonly property string iconFontFamily: userConfig.iconFontFamily

    // --- Placement ----------------------------------------------------------
    readonly property real topMargin: Math.max(6, userConfig.islandTopMargin)
    readonly property real restingHeight: tokens.idleCompact.height
    readonly property real restingWidth: tokens.idleCompact.width

    // --- Live activity sources ---------------------------------------------
    readonly property bool recordingLive: root.captureController
        ? root.captureController.recording
        : false
    readonly property bool mediaLive: media.live

    // --- Transient state ----------------------------------------------------
    // "" | "notification" | "shot" | "volume"
    property string transientActivity: ""
    // "" | "launcher" | "clipboard" | "notify" | "workspaces" — keyboard-driven
    // panels; only one can be open and they always open expanded.
    property string panelActivity: ""
    property bool controlCentreOpen: false
    property real life: 1

    property string notificationApp: ""
    property string notificationSummary: ""
    property string notificationBody: ""
    property string screenshotPath: ""
    property var bannerItem: null
    property real volumeValue: 0
    property bool volumeMuted: false

    // --- Resolved activity --------------------------------------------------
    readonly property string activity: {
        if (root.panelActivity !== "")
            return root.panelActivity;
        if (root.transientActivity !== "")
            return root.transientActivity;
        if (root.controlCentreOpen)
            return "control";
        if (root.recordingLive)
            return "recording";
        if (root.mediaLive)
            return "media";
        return "idle";
    }

    readonly property bool keyboardPanel: root.panelActivity !== ""

    readonly property bool hasExpanded: root.activity === "launcher"
        || root.activity === "clipboard"
        || root.activity === "notify"
        || root.activity === "workspaces"
        || root.activity === "media"
        || root.activity === "recording"
        || root.activity === "control"
        || root.activity === "shot"
        || root.activity === "notification"

    property bool expanded: false

    readonly property size targetSize: {
        switch (root.activity) {
        case "media":
            return root.expanded ? tokens.mediaExpanded : tokens.mediaCompact;
        case "recording":
            return root.expanded ? tokens.recordingExpanded : tokens.recordingCompact;
        case "control":
            return root.expanded ? tokens.controlExpanded : tokens.controlCompact;
        case "shot":
            return root.expanded ? tokens.shotExpanded : tokens.shotCompact;
        case "notification":
            return root.expanded ? tokens.notificationExpanded : tokens.notificationCompact;
        case "launcher":
            return root.expanded ? tokens.launcherExpanded : tokens.launcherCompact;
        case "clipboard":
            return root.expanded ? tokens.clipboardExpanded : tokens.clipboardCompact;
        case "notify":
            return root.expanded ? tokens.notifyExpanded : tokens.notifyCompact;
        case "workspaces":
            return root.expanded ? tokens.workspacesExpanded : tokens.workspacesCompact;
        case "banner":
            return tokens.notifyBanner;
        case "volume":
            return tokens.volumeCompact;
        default:
            return tokens.idleCompact;
        }
    }

    // Auto-dismiss per activity, matching the reference `autoDismiss` column.
    readonly property int dismissMs: {
        switch (root.transientActivity) {
        case "notification":
            return 6000;
        case "shot":
            return 6000;
        case "banner":
            return 5000;
        case "volume":
            return 2200;
        default:
            return 0;
        }
    }

    screen: screenObject
    color: StyleTokens.transparent
    anchors { top: true; left: true; right: true }
    exclusiveZone: Math.round(root.topMargin + root.restingHeight)
    implicitHeight: Math.ceil(root.topMargin + tokens.mediaExpanded.height + 28)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tide-island-nucleus"
    // Search fields and grid navigation need real key events; everything else
    // stays click-through and focus-free.
    WlrLayershell.keyboardFocus: root.keyboardPanel
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    // Only the capsule takes input; the rest of the strip stays click-through.
    mask: Region {
        x: Math.floor(capsule.x)
        y: Math.floor(capsule.y)
        width: Math.ceil(capsule.width)
        height: Math.ceil(capsule.height)
    }

    IslandTokens { id: tokens }
    IslandMotion { id: motion }

    MediaSource { id: media }

    // Shared, single-instance sources owned by shell.qml (one notification
    // server / cliphist reader per shell, not per monitor).
    Connections {
        target: root.notifications

        function onReceived(item) {
            if (root.panelActivity !== "")
                return;
            root.bannerItem = item;
            root.showTransient("banner");
        }
    }

    // ----------------------------------------------------------------- logic
    onActivityChanged: {
        // Transients open expanded (they carry content and actions); live
        // activities stay compact until touched, exactly like iOS.
        root.expanded = root.activity === "shot"
            || root.activity === "notification"
            || root.activity === "control"
            || root.keyboardPanel;
        pressTimer.stop();
    }

    function showTransient(kind) {
        root.transientActivity = kind;
        root.life = 1;
        lifeAnimation.restart();
        dismissTimer.restart();
    }

    function clearTransient() {
        lifeAnimation.stop();
        dismissTimer.stop();
        root.transientActivity = "";
        root.life = 1;
    }

    function showNotification(appName, summary, body) {
        root.notificationApp = String(appName);
        root.notificationSummary = String(summary);
        root.notificationBody = String(body);
        root.showTransient("notification");
    }

    function showScreenshot(path) {
        root.screenshotPath = String(path);
        root.showTransient("shot");
    }

    function dismissScreenshot() {
        if (root.transientActivity === "shot")
            root.clearTransient();
    }

    function showVolume(value, muted) {
        root.volumeValue = Math.max(0, Math.min(1, Number(value)));
        root.volumeMuted = !!muted;
        root.showTransient("volume");
    }

    // --- Keyboard panels ---------------------------------------------------
    function openPanel(kind) {
        root.clearTransient();
        root.controlCentreOpen = false;
        root.panelActivity = root.panelActivity === kind ? "" : kind;
    }

    function closePanel() {
        root.panelActivity = "";
    }

    function toggleLauncher() { root.openPanel("launcher"); }
    function toggleClipboard() { root.openPanel("clipboard"); }
    function toggleNotifications() { root.openPanel("notify"); }
    function toggleWorkspaces() { root.openPanel("workspaces"); }

    function toggleControlCentre() {
        root.clearTransient();
        root.controlCentreOpen = !root.controlCentreOpen;
    }

    function openControlCentre() {
        root.clearTransient();
        root.controlCentreOpen = true;
    }

    function closeControlCentre() {
        root.controlCentreOpen = false;
    }

    Timer {
        id: dismissTimer

        interval: root.dismissMs > 0 ? root.dismissMs : 1
        running: false
        onTriggered: root.clearTransient()
    }

    NumberAnimation {
        id: lifeAnimation

        target: root
        property: "life"
        from: 1
        to: 0
        duration: root.dismissMs > 0 ? root.dismissMs : 1
    }

    Timer {
        id: pressTimer

        interval: motion.longPressInterval
        onTriggered: {
            if (root.hasExpanded)
                root.expanded = true;
        }
    }

    Connections {
        target: root.captureController

        function onScreenshotCaptured(path) {
            root.showScreenshot(path);
        }

        function onScreenshotDismissed() {
            root.dismissScreenshot();
        }
    }

    Connections {
        target: SystemServices

        function onVolumeSnapshotReady(value, muted, errorString) {
            if (value >= 0) {
                root.volumeValue = Math.max(0, Math.min(1, value));
                root.volumeMuted = !!muted;
            }
        }
    }

    // ---------------------------------------------------------------- capsule
    Item {
        id: capsuleHost

        x: Math.round((root.width - capsule.width) / 2)
        y: root.topMargin
        width: capsule.width
        height: capsule.height

        Rectangle {
            id: capsule

            width: root.targetSize.width
            height: root.targetSize.height
            radius: Math.min(height / 2, 32)
            color: "#000000"
            clip: true
            scale: pointer.pressed ? motion.pressScale : 1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#bf000000"
                shadowBlur: 0.85
                shadowVerticalOffset: 14
            }

            Behavior on width {
                SpringAnimation {
                    spring: motion.shapeSpring
                    damping: motion.shapeDamping
                    mass: motion.shapeMass
                    epsilon: motion.shapeEpsilon
                }
            }

            Behavior on height {
                SpringAnimation {
                    spring: motion.shapeSpring
                    damping: motion.shapeDamping
                    mass: motion.shapeMass
                    epsilon: motion.shapeEpsilon
                }
            }

            Behavior on scale {
                SpringAnimation {
                    spring: motion.buttonSpring
                    damping: motion.buttonDamping
                    mass: 1.0
                    epsilon: 0.005
                }
            }

            // Vibrancy sheen from the reference: a whisper of white down the top
            // fifth so the black never reads as flat.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#12ffffff" }
                    GradientStop { position: 0.22; color: "#05ffffff" }
                    GradientStop { position: 0.6; color: "#00ffffff" }
                }
            }

            // --- Content ---------------------------------------------------
            Loader {
                anchors.fill: parent
                active: root.activity === "idle"
                sourceComponent: IdleLayer { showCondition: true }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "media" && !root.expanded
                sourceComponent: MediaCompactLayer {
                    title: media.title
                    artUrl: media.artUrl
                    playing: media.playing
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "media" && root.expanded
                sourceComponent: MediaExpandedLayer {
                    title: media.title
                    artist: media.artist
                    artUrl: media.artUrl
                    playing: media.playing
                    progress: media.progress
                    elapsedText: media.elapsedText
                    remainingText: media.remainingText
                    textFontFamily: root.textFontFamily
                    heroFontFamily: root.heroFontFamily
                    iconFontFamily: root.iconFontFamily
                    onPlayPauseRequested: media.togglePlaying()
                    onNextRequested: media.next()
                    onPreviousRequested: media.previous()
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "recording" && !root.expanded
                sourceComponent: RecordingCompactLayer {
                    elapsedText: root.captureController ? root.captureController.elapsedText : "00:00"
                    paused: root.captureController ? root.captureController.recordingPaused : false
                    sourceLabel: root.captureController && root.captureController.recordingRegion
                        ? "Region"
                        : "Screen"
                    textFontFamily: root.textFontFamily
                    heroFontFamily: root.heroFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "recording" && root.expanded
                sourceComponent: CaptureRecordingLayer {
                    elapsedText: root.captureController ? root.captureController.elapsedText : "00:00"
                    paused: root.captureController ? root.captureController.recordingPaused : false
                    sourceLabel: root.captureController && root.captureController.recordingRegion
                        ? "Region"
                        : "Screen"
                    textFontFamily: root.textFontFamily
                    heroFontFamily: root.heroFontFamily
                    iconFontFamily: root.iconFontFamily
                    onPauseToggleRequested: {
                        if (root.captureController)
                            root.captureController.togglePauseRecording();
                    }
                    onStopRequested: {
                        if (root.captureController)
                            root.captureController.stopRecording();
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "shot" && !root.expanded
                sourceComponent: ShotCompactLayer {
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "shot" && root.expanded
                sourceComponent: CaptureShotLayer {
                    filePath: root.screenshotPath
                    lifeProgress: root.life
                    textFontFamily: root.textFontFamily
                    heroFontFamily: root.heroFontFamily
                    iconFontFamily: root.iconFontFamily
                    onCopyRequested: {
                        if (root.captureController)
                            root.captureController.copyLastScreenshot();
                        root.clearTransient();
                    }
                    onAnnotateRequested: {
                        if (root.captureController)
                            root.captureController.annotateLastScreenshot();
                        root.clearTransient();
                    }
                    onOpenRequested: {
                        if (root.captureController)
                            root.captureController.openLastScreenshot();
                        root.clearTransient();
                    }
                    onDeleteRequested: {
                        if (root.captureController)
                            root.captureController.deleteLastScreenshot();
                        root.clearTransient();
                    }
                    onDismissRequested: root.clearTransient()
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "control" && !root.expanded
                sourceComponent: ControlCompactLayer {
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "control" && root.expanded
                sourceComponent: IosControlCenterLayer {
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "notification"
                sourceComponent: NotificationCardLayer {
                    appName: root.notificationApp
                    summary: root.notificationSummary
                    body: root.notificationBody
                    lifeProgress: root.life
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "launcher" && !root.expanded
                sourceComponent: LauncherCompactLayer {
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "launcher" && root.expanded
                sourceComponent: LauncherExpandedLayer {
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                    onCloseRequested: root.closePanel()
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "clipboard" && !root.expanded
                sourceComponent: ClipboardCompactLayer {
                    count: root.clipboard ? root.clipboard.count : 0
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "clipboard" && root.expanded
                sourceComponent: ClipboardExpandedLayer {
                    source: root.clipboard
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                    onCloseRequested: root.closePanel()
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "notify" && !root.expanded
                sourceComponent: NotifyCompactLayer {
                    count: root.notifications ? root.notifications.count : 0
                    dnd: root.notifications ? root.notifications.dnd : false
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "notify" && root.expanded
                sourceComponent: NotifyExpandedLayer {
                    source: root.notifications
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                    onCloseRequested: root.closePanel()
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "workspaces" && !root.expanded
                sourceComponent: WorkspacesCompactLayer {
                    source: root.workspaces
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "workspaces" && root.expanded
                sourceComponent: WorkspacesExpandedLayer {
                    source: root.workspaces
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                    onCloseRequested: root.closePanel()
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "banner"
                sourceComponent: NotifyBannerLayer {
                    item: root.bannerItem
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }

            Loader {
                anchors.fill: parent
                active: root.activity === "volume"
                sourceComponent: VolumeHudLayer {
                    value: root.volumeValue
                    muted: root.volumeMuted
                    textFontFamily: root.textFontFamily
                    iconFontFamily: root.iconFontFamily
                }
            }
        }

        // Tap toggles, long-press forces the expanded card. Buttons inside the
        // layers sit above this area, so their clicks are not stolen.
        MouseArea {
            id: pointer

            anchors.fill: capsule
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            z: -1

            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton)
                    pressTimer.restart();
            }

            onReleased: pressTimer.stop()

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    if (root.panelActivity !== "")
                        root.closePanel();
                    else if (root.transientActivity !== "")
                        root.clearTransient();
                    else
                        root.closeControlCentre();
                    return;
                }
                if (root.activity === "banner") {
                    root.clearTransient();
                    root.openPanel("notify");
                    return;
                }
                if (root.hasExpanded)
                    root.expanded = !root.expanded;
            }

            // Hovering pauses a transient's countdown, like the reference build.
            onContainsMouseChanged: {
                if (root.dismissMs <= 0)
                    return;
                if (containsMouse) {
                    lifeAnimation.pause();
                    dismissTimer.stop();
                } else {
                    lifeAnimation.resume();
                    dismissTimer.interval = Math.max(1, Math.round(root.dismissMs * root.life));
                    dismissTimer.restart();
                }
            }
        }
    }
}
