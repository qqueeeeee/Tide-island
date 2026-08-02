import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import IslandBackend
import "qml/common"
import "qml/controlcenter"
import "qml/connectivity"
import "qml/island"
import "qml/workspace"

PanelWindow {
    id: root
    property var shellRootController: null
    property string overviewPhase: "closed"
    property bool overviewPreloading: false
    readonly property bool overviewPreparing: overviewPhase === "preparing"
    readonly property bool overviewVisible: overviewPhase === "preparing" || overviewPhase === "opening" || overviewPhase === "open"
    readonly property bool overviewMounted: overviewPhase !== "closed" || overviewPreloading
    readonly property bool overviewLoaderActive: !compositorIsNiri
        && (overviewMounted || overviewUnloadGraceTimer.running)
    readonly property bool overviewDataReady: overviewLoader.item
        ? !!overviewLoader.item.overviewDataReady
        : false
    readonly property bool overviewWallpaperReady: overviewWallpaperCache.ready
    readonly property bool overviewVisualReady: overviewDataReady && overviewWallpaperReady
    readonly property bool overviewContentVisible: (overviewPhase === "opening" || overviewPhase === "open")
        && overviewVisualReady
    readonly property bool compositorIsNiri: CompositorBackend.compositor === "niri"
    readonly property int compositorRevision: CompositorBackend.revision
    readonly property string screenOutputName: screen && screen.name !== undefined ? String(screen.name) : ""
    readonly property var hyprlandIntegration: hyprlandIntegrationLoader.item
    readonly property var hyprMonitor: hyprlandIntegration ? hyprlandIntegration.monitor : null
    readonly property string hyprMonitorName: hyprlandIntegration ? hyprlandIntegration.monitorName : ""
    readonly property string compositorOutputName: compositorIsNiri ? screenOutputName : hyprMonitorName
    readonly property bool monitorFocused: {
        compositorRevision;
        return compositorIsNiri
            ? CompositorBackend.isOutputFocused(screenOutputName)
            : (hyprlandIntegration ? hyprlandIntegration.monitorFocused : false);
    }
    readonly property bool connectivityPromptActive: controlCenterLoader.item
        ? controlCenterLoader.item.hasConnectivityPrompt
        : false
    readonly property var controlCenterRef: controlCenterLoader.item
    readonly property int currentMonitorWorkspaceId: {
        compositorRevision;
        return compositorIsNiri
            ? CompositorBackend.activeWorkspaceIndexForOutput(screenOutputName)
            : (hyprlandIntegration ? hyprlandIntegration.workspaceId : 1);
    }
    readonly property bool screenRecordingActive: shellRootController
        && shellRootController.screenRecordingActive !== undefined
        ? !!shellRootController.screenRecordingActive
        : false
    readonly property var captureController: shellRootController
        && shellRootController.captureController
        ? shellRootController.captureController
        : null
    readonly property bool captureRecordingActive: captureController
        ? !!captureController.recording
        : false
    readonly property string captureElapsedText: captureController
        ? String(captureController.elapsedText)
        : ""
    property string captureScreenshotPath: ""
    property bool autoHideVisible: false
    property bool autoHidePointerInside: false
    property bool autoHideForcedHidden: false
    property string autoHideRevealSource: "none"

    readonly property var userConfig: UserConfig

    Loader {
        id: hyprlandIntegrationLoader

        active: !root.compositorIsNiri
        asynchronous: false
        source: active ? "qml/island/HyprlandWindowIntegration.qml" : ""
    }

    Binding {
        target: hyprlandIntegrationLoader.item
        property: "screenObject"
        value: root.screen
        when: hyprlandIntegrationLoader.item !== null
    }

    color: StyleTokens.transparent
    anchors { top: true; left: true; right: true }
    mask: Region {
        // Input is the union of the island's visible surfaces plus a compact top
        // gesture strip. The gesture strip must not grow with expanded content.
        Region {
            x: Math.floor(root.topGestureInputX)
            y: 0
            width: Math.ceil(root.topGestureInputWidth)
            height: Math.ceil(root.topGestureInputHeight)
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(mainCapsule.x)
            y: Math.floor(mainCapsule.y)
            width: Math.ceil(mainCapsule.width)
            height: Math.ceil(mainCapsule.height)
        }
        
        // Add existing detail shells
        Region {
            intersection: Intersection.Combine
            x: Math.floor(wifiConnectivityDetailShell.x)
            y: Math.floor(wifiConnectivityDetailShell.y)
            width: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.width) : 0
            height: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(bluetoothConnectivityDetailShell.x)
            y: Math.floor(bluetoothConnectivityDetailShell.y)
            width: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.width) : 0
            height: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.height) : 0
        }

    }
    readonly property real capsuleWindowHeight: Math.ceil(
        root.islandTopOffset + mainCapsule.targetHeight + 12
    )
    readonly property real connectivityDetailWindowHeight: root.anyConnectivityDetailMounted
        ? Math.ceil(root.islandTopOffset + root.connectivityDetailHeight + 12)
        : 0
    readonly property real overviewWindowHeight: root.overviewVisible
        ? Math.ceil(root.islandTopOffset + root.overviewCapsuleHeight + 8)
        : 0
    // The status bar lives in its own surface (qml/bar/StatusBarWindow.qml), so
    // it no longer contributes to this window's height.
    readonly property real statusBarReserveHeight: root.userConfig.statusBarEnabled
        ? Math.ceil(root.islandTopOffset + root.islandRestingHeight)
        : 0
    readonly property real requestedWindowHeight: Math.max(
        root.notificationCenterWindowHeight,
        root.capsuleWindowHeight,
        root.connectivityDetailWindowHeight,
        root.overviewWindowHeight,
        Math.ceil(root.controlCenterWindowHeight)
    )
    // Grow the layer surface immediately, but keep the old extent while the
    // capsule finishes its collapse animation. A later expansion interrupts
    // the pending shrink instead of letting a stale timer clip new content.
    property real retainedWindowHeight: 0
    implicitHeight: Math.max(root.requestedWindowHeight, root.retainedWindowHeight)

    function reconcileWindowHeight() {
        if (root.requestedWindowHeight >= root.retainedWindowHeight) {
            windowShrinkTimer.stop();
            root.retainedWindowHeight = root.requestedWindowHeight;
            return;
        }

        windowShrinkTimer.restart();
    }

    onRequestedWindowHeightChanged: root.reconcileWindowHeight()
    Component.onCompleted: root.retainedWindowHeight = root.requestedWindowHeight

    exclusiveZone: Math.ceil(root.baseExclusiveZone * root.exclusiveZoneProgress)
    WlrLayershell.layer: islandContainer.wallpaperPickerLayerVisible
        || islandContainer.applicationLauncherLayerVisible
        ? WlrLayer.Overlay
        : WlrLayer.Top
    WlrLayershell.keyboardFocus: {
        if (islandContainer.wallpaperPickerLayerVisible
                || islandContainer.applicationLauncherLayerVisible)
            return WlrKeyboardFocus.Exclusive;
        // Keep keyboard focus on the overview until an overview action closes it.
        // Click-to-focus closes the overview before focusing the selected client.
        if (root.monitorFocused && root.overviewVisible)
            return WlrKeyboardFocus.Exclusive;
        if (islandContainer.expandedPlayerKeyboardFocusRequested)
            return WlrKeyboardFocus.OnDemand;
        if (root.monitorFocused && root.connectivityPromptActive)
            return WlrKeyboardFocus.OnDemand;
        return WlrKeyboardFocus.None;
    }
    readonly property string iconFontFamily: userConfig.iconFontFamily
    readonly property string textFontFamily: userConfig.textFontFamily
    readonly property string heroFontFamily: userConfig.heroFontFamily
    readonly property string timeFontFamily: userConfig.timeFontFamily
    readonly property int bodyFontSize: userConfig.bodyFontSize
    readonly property int titleFontSize: userConfig.titleFontSize
    readonly property int iconFontSize: userConfig.iconFontSize
    readonly property string defaultSplitIcon: "\ud83c\udfa7"
    readonly property string notificationStatusIcon: "\uf0f3"
    readonly property real overviewWindowCornerRadius: 12

    // --- macOS Dynamic Island (notch) metrics ---
    // Matches the macOS notch shells (NotchNook / Boring Notch): the capsule is
    // welded to the top edge of the screen, top corners are square so it reads as
    // part of the display bezel, and only the bottom corners are rounded.
    readonly property bool macNotchStyle: userConfig.islandMacNotchStyle
    // The island is a true mobile-style capsule at every size now: the notch
    // chrome (square top corners, bezel shoulders, welded top edge) is retired,
    // while `macNotchStyle` keeps driving the wider macOS-ish size metrics.
    readonly property bool notchChromeVisible: false
    readonly property real macNotchRestingWidth: 208
    readonly property real macNotchRestingHeight: 34
    readonly property real macNotchShoulder: 11
    readonly property real islandRestingWidth: root.macNotchStyle
        ? root.macNotchRestingWidth
        : userConfig.islandWidth
    readonly property real islandRestingHeight: root.macNotchStyle
        ? root.macNotchRestingHeight
        : userConfig.islandHeight
    // Even in notch-metrics mode the pill floats: a welded top edge cannot be a
    // capsule.
    readonly property real islandTopOffset: root.macNotchStyle
        ? Math.max(6, userConfig.islandTopMargin)
        : userConfig.islandTopMargin

    // --- Morph metrics ---
    // iOS reference: iPhone 15/16 Pro idle pill 125x37pt, compact ~200pt,
    // expanded Live Activity 371x160pt with a 44pt continuous radius.
    // macOS reference: notch shells stay narrow when compact and open into a
    // wide 480x190 panel with a 22pt bottom radius.
    readonly property real iosScale: root.islandRestingHeight / 37.0
    readonly property real iosCompactWidth: root.macNotchStyle
        ? root.macNotchRestingWidth * 1.26
        : root.islandRestingWidth * (200.0 / 125.0)
    readonly property real iosExpandedWidth: Math.min(
        root.width - 48,
        root.macNotchStyle ? 480 : root.islandRestingWidth * (371.0 / 125.0)
    )
    readonly property real iosExpandedHeight: root.macNotchStyle
        ? 190
        : root.islandRestingHeight * (160.0 / 37.0)
    readonly property real iosNotificationHeight: root.macNotchStyle
        ? 62
        : root.islandRestingHeight * (56.0 / 37.0)
    readonly property var iosMorphCurve: [0.32, 0.72, 0.0, 1.0, 1.0, 1.0]

    // Exact metrics from the approved iOS reference build (SPECS table),
    // clamped so the capsule never overruns a narrow display.
    readonly property real iosRecordingWidth: Math.min(root.width - 48, 340)
    readonly property real iosRecordingHeight: 92
    readonly property real iosShotWidth: Math.min(root.width - 48, 348)
    readonly property real iosShotHeight: 106
    readonly property real iosControlWidth: Math.min(root.width - 48, 372)
    readonly property real iosControlHeight: 178

    // One rule for every size: radius is always half the height, so the shape is
    // a perfect capsule whether it is the resting pill, a compact activity or a
    // fully expanded card-sized pill. Derived from the live height, so corners
    // can never fall out of sync with the springing shape.
    function capsuleRadiusForHeight(shapeHeight) {
        return Math.max(0, shapeHeight / 2);
    }


    readonly property int dynamicIslandAcceptedButtons: userConfig.mouseButtonsMask([
        1,
        userConfig.dynamicIslandPrimaryButton,
        userConfig.dynamicIslandSecondaryButton
    ])
    readonly property int configuredHoverExpandAction: {
        const action = Number(userConfig.hoverExpandAction);
        return isNaN(action) ? 0 : Math.max(0, Math.min(2, Math.round(action)));
    }
    // In notch mode the reserved strip must end exactly at the bottom of the
    // notch / bar content, otherwise a thin gap shows above tiled windows.
    readonly property real baseExclusiveZone: root.macNotchStyle
        ? Math.ceil(Math.max(root.islandTopOffset + root.islandRestingHeight,
                             root.statusBarReserveHeight))
        : userConfig.islandExclusiveZone
    readonly property bool hoverExpandEnabled: configuredHoverExpandAction > 0
    readonly property bool topGestureInputActive: !root.overviewVisible && islandContainer.canShowSideSwipe
    readonly property bool autoHideRuntimeEnabled: !shellRootController
        || shellRootController.islandAutoHideRuntimeEnabled === undefined
        || !!shellRootController.islandAutoHideRuntimeEnabled
    readonly property bool autoHideEnabled: userConfig.islandAutoHideEnabled && autoHideRuntimeEnabled
    readonly property bool autoHideRestingState: islandContainer.islandState === "normal"
        || islandContainer.islandState === "custom"
        || islandContainer.islandState === "lyrics"
    readonly property bool autoHideCanHideNow: autoHideEnabled
        && autoHideRestingState
        && !root.overviewVisible
        && !root.connectivityPromptActive
        && !root.anyConnectivityDetailMounted
    readonly property bool autoHideMustShow: !autoHideRestingState
        || root.overviewVisible
        || root.connectivityPromptActive
        || root.anyConnectivityDetailMounted
    readonly property bool autoHideTargetVisible: autoHideMustShow
        || (!autoHideForcedHidden && (!autoHideEnabled || autoHideVisible))
    readonly property bool autoHideSuppressesTransientReveal: (autoHideEnabled || autoHideForcedHidden)
        && !autoHideTargetVisible
    property real autoHideProgress: autoHideTargetVisible ? 1 : 0
    readonly property bool exclusiveZoneTargetActive: (!autoHideEnabled && autoHideTargetVisible)
        || (autoHideRevealSource === "edge" && autoHideTargetVisible)
        || islandContainer.notificationLayerVisible
    property real exclusiveZoneProgress: exclusiveZoneTargetActive ? 1 : 0
    readonly property real autoHideRevealWidth: Math.min(root.width, Math.max(root.islandRestingWidth + 120, 240))
    readonly property real autoHideRevealHeight: autoHideEnabled ? 10 : 0
    readonly property real autoHideRevealX: Math.max(
        0,
        Math.min(root.width - autoHideRevealWidth, root.width * userConfig.islandPositionX / 100 - autoHideRevealWidth / 2)
    )
    readonly property real topGestureInputX: autoHideEnabled ? autoHideRevealX : 0
    readonly property real topGestureInputWidth: topGestureInputActive
        ? (autoHideEnabled ? autoHideRevealWidth : root.width)
        : 0
    readonly property real topGestureInputHeight: topGestureInputActive
        ? (autoHideEnabled ? autoHideRevealHeight : root.baseExclusiveZone)
        : 0
    readonly property real overviewCapsuleWidth: islandContainer.overviewView ? islandContainer.overviewView.width : 760
    readonly property real overviewCapsuleHeight: islandContainer.overviewView ? islandContainer.overviewView.height : 308
    readonly property real overviewCapsuleRadius: islandContainer.overviewView
        ? islandContainer.overviewView.largeWorkspaceRadius + islandContainer.overviewView.outerPadding
        : 44
    readonly property color overviewCapsuleColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardColor
        : StyleTokens.overviewCard
    readonly property color overviewCapsuleBorderColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardBorderColor
        : StyleTokens.overviewBorder
    property bool wifiConnectivityDetailOpen: false
    property bool wifiConnectivityDetailMounted: false
    property bool bluetoothConnectivityDetailOpen: false
    property bool bluetoothConnectivityDetailMounted: false
    readonly property bool anyConnectivityDetailMounted: wifiConnectivityDetailMounted || bluetoothConnectivityDetailMounted
    readonly property real connectivityDetailWidth: 318
    readonly property real connectivityDetailHeight: 404
    readonly property real controlCenterMaximumExtraHeight: controlCenterLoader.item
        ? controlCenterLoader.item.controlCenterMaximumExtraHeight
        : 120
    readonly property real controlCenterWindowHeight: islandContainer.controlCenterLayerVisible
        ? root.islandTopOffset + 320 + root.controlCenterMaximumExtraHeight + 12
        : 0

    readonly property real notificationCenterWindowHeight: islandContainer.notificationCenterLayerVisible
        ? root.islandTopOffset + (notificationCenterLoader.item ? notificationCenterLoader.item.contentHeight : 400) + 6
        : 0
    readonly property real connectivityDetailGap: 16
    readonly property int connectivityDetailAnimationDuration: 360
    readonly property string overviewWallpaperSource: overviewWallpaperCache.effectiveSource
    property string wallpaperPickerActiveWallpaper: userConfig.wallpaperPath

    Behavior on autoHideProgress {
        NumberAnimation {
            duration: root.autoHideTargetVisible ? 120 : 300
            easing.type: root.autoHideTargetVisible ? Easing.OutCubic : Easing.InCubic
        }
    }

    Behavior on exclusiveZoneProgress {
        NumberAnimation {
            duration: root.exclusiveZoneTargetActive ? 120 : 300
            easing.type: root.exclusiveZoneTargetActive ? Easing.OutCubic : Easing.InCubic
        }
    }

    function setAutoHideRevealSource(source) {
        if (source === undefined || source === null)
            return;

        const nextSource = String(source);
        autoHideRevealSource = nextSource === "edge" || nextSource === "state" || nextSource === "manual"
            ? nextSource
            : "manual";
    }

    function showAutoHiddenIsland(source) {
        setAutoHideRevealSource(source);
        autoHideForcedHidden = false;
        if (!autoHideEnabled) {
            autoHideHideTimer.stop();
            autoHideVisible = true;
            return;
        }

        autoHideHideTimer.stop();
        autoHideVisible = true;
    }

    function scheduleAutoHide() {
        if (!autoHideEnabled) {
            autoHideHideTimer.stop();
            autoHideVisible = true;
            return;
        }

        if (!autoHideCanHideNow) {
            autoHideHideTimer.stop();
            showAutoHiddenIsland("state");
            return;
        }

        if (autoHidePointerInside) {
            autoHideHideTimer.stop();
            return;
        }

        autoHideHideTimer.interval = Math.max(100, Math.min(10000, userConfig.islandAutoHideDelayMs));
        autoHideHideTimer.restart();
    }

    function hideAutoHiddenIsland(force) {
        if (force === undefined) force = false;
        if (!autoHideEnabled) {
            autoHideHideTimer.stop();
            if (!force && autoHideMustShow)
                return;
            autoHideForcedHidden = true;
            autoHideRevealSource = "none";
            autoHideVisible = false;
            return;
        }

        if (!force && (!autoHideCanHideNow || autoHidePointerInside))
            return;

        autoHideHideTimer.stop();
        autoHideForcedHidden = false;
        autoHideRevealSource = "none";
        autoHideVisible = false;
    }

    function toggleAutoHiddenIsland() {
        if (autoHideTargetVisible)
            hideAutoHiddenIsland(false);
        else
            showAutoHiddenIsland("manual");
    }

    function showIslandWindow() {
        showAutoHiddenIsland("manual");
    }

    function hideIslandWindow() {
        autoHidePointerInside = false;
        hideAutoHiddenIsland(false);
    }

    function toggleIslandWindow() {
        toggleAutoHiddenIsland();
    }

    function refreshAutoHideWindow() {
        if (autoHideEnabled)
            scheduleAutoHide();
        else
            showAutoHiddenIsland("manual");
    }

    function beginOverviewOpening() {
        if (!overviewPreparing) return;
        if (overviewLoader.status !== Loader.Ready || !overviewVisualReady) return;
        overviewPreloading = false;
        overviewPhase = "opening";
        overviewRevealTimer.restart();
    }

    function prepareOverview() {
        if (compositorIsNiri) return;
        if (overviewPhase !== "closed") return;
        overviewUnloadGraceTimer.stop();
        overviewPreloading = true;
        overviewPreloadExpireTimer.restart();
    }

    function cancelPreparedOverview() {
        if (compositorIsNiri) return;
        if (overviewPhase !== "closed") return;
        overviewPreloadExpireTimer.stop();
        overviewPreloading = false;
    }

    function openOverview() {
        if (compositorIsNiri)
            return;
        if (overviewPhase !== "closed") return;
        overviewUnloadGraceTimer.stop();
        overviewPreloadExpireTimer.stop();
        overviewPreloading = true;
        overviewPhase = "preparing";
        if (overviewLoader.status === Loader.Ready) {
            beginOverviewOpening();
        }
    }

    function closeOverview() {
        if (compositorIsNiri)
            return;
        if (!overviewMounted) return;
        if (overviewLoader.status === Loader.Ready)
            overviewUnloadGraceTimer.restart();
        overviewRevealTimer.stop();
        overviewPreloadExpireTimer.stop();
        islandContainer.restoreRestingCapsule(true);
        overviewPreloading = false;
        overviewPhase = "closed";
    }

    function closeOverviewEverywhere() {
        if (shellRootController && shellRootController.closeOverviewAll) {
            shellRootController.closeOverviewAll();
            return;
        }

        closeOverview();
    }

    function setConnectivityDetailVisible(kind, open) {
        const nextOpen = !!open;

        if (kind === "wifi") {
            if (nextOpen) {
                wifiConnectivityDetailCleanupTimer.stop();
                wifiConnectivityDetailMounted = true;
                wifiConnectivityDetailOpen = true;
            } else {
                if (!wifiConnectivityDetailMounted && !wifiConnectivityDetailOpen)
                    return;
                wifiConnectivityDetailOpen = false;
                wifiConnectivityDetailCleanupTimer.restart();
            }
            return;
        }

        if (kind === "bluetooth") {
            if (nextOpen) {
                bluetoothConnectivityDetailCleanupTimer.stop();
                bluetoothConnectivityDetailMounted = true;
                bluetoothConnectivityDetailOpen = true;
            } else {
                if (!bluetoothConnectivityDetailMounted && !bluetoothConnectivityDetailOpen)
                    return;
                bluetoothConnectivityDetailOpen = false;
                bluetoothConnectivityDetailCleanupTimer.restart();
            }
        }
    }

    function closeAllConnectivityDetails() {
        setConnectivityDetailVisible("wifi", false);
        setConnectivityDetailVisible("bluetooth", false);
    }

    function openOverviewEverywhere() {
        if (shellRootController && shellRootController.openOverviewAll) {
            shellRootController.openOverviewAll();
            return;
        }

        openOverview();
    }

    function prepareOverviewEverywhere() {
        if (shellRootController && shellRootController.prepareOverviewAll) {
            shellRootController.prepareOverviewAll();
            return;
        }

        prepareOverview();
    }

    function cancelPreparedOverviewEverywhere() {
        if (shellRootController && shellRootController.cancelPreparedOverviewAll) {
            shellRootController.cancelPreparedOverviewAll();
            return;
        }

        cancelPreparedOverview();
    }

    function toggleOverviewEverywhere() {
        if (compositorIsNiri)
            return;

        if (shellRootController && shellRootController.toggleOverviewAll) {
            shellRootController.toggleOverviewAll();
            return;
        }

        if (overviewMounted)
            closeOverviewEverywhere();
        else
            openOverviewEverywhere();
    }

    function prewarmWallpaperCache() {
        overviewWallpaperCache.prewarm();
    }

    function handleWallpaperApplySucceeded(filePath) {
        wallpaperPickerActiveWallpaper = filePath;
        if (shellRootController && shellRootController.refreshOverviewWallpaperCaches)
            shellRootController.refreshOverviewWallpaperCaches(filePath);
        else
            prewarmWallpaperCache();
    }

    function toggleCaptureRecordingWindow(region) {
        if (root.captureController)
            root.captureController.toggleRecording(region === true);
    }

    function captureScreenshotWindow(mode) {
        if (root.captureController)
            root.captureController.takeScreenshot(mode);
    }

    function showCaptureScreenshotWindow(filePath) {
        if (!root.userConfig.captureShowScreenshotPreview)
            return;

        root.captureScreenshotPath = filePath === undefined || filePath === null ? "" : String(filePath);
        if (root.captureScreenshotPath === "")
            return;

        showAutoHiddenIsland("state");
        islandContainer.showCaptureScreenshot();
        captureScreenshotDismissTimer.restart();
    }

    function dismissCaptureScreenshotWindow() {
        captureScreenshotDismissTimer.stop();
        root.captureScreenshotPath = "";
        if (islandContainer.islandState === "capture_screenshot")
            islandContainer.smartRestoreState();
        scheduleAutoHide();
    }

    function refreshCaptureRecordingWindow() {
        if (root.captureRecordingActive) {
            showAutoHiddenIsland("state");
            islandContainer.showCaptureRecording();
        } else if (islandContainer.islandState === "capture_recording") {
            islandContainer.smartRestoreState();
            scheduleAutoHide();
        }
    }

    onCaptureRecordingActiveChanged: root.refreshCaptureRecordingWindow()

    Timer {
        id: captureScreenshotDismissTimer

        interval: Math.max(2, root.userConfig.captureScreenshotPreviewSeconds) * 1000
        repeat: false
        onTriggered: root.dismissCaptureScreenshotWindow()
    }

    function showNotification(appName, summary, body) {
        islandContainer.showNotificationCapsule(appName, summary, body);
    }

    function showClockWindow() {
        islandContainer.showTimeCapsule();
        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }
    function showCustomInfoWindow() {
        islandContainer.showCustomCapsule();
        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }
    function showLyricsWindow() {
        islandContainer.showLyricsCapsule();
        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }

    function swipeRightWindow() {
        if (islandContainer.restingState === "lyrics")
            islandContainer.showTimeCapsule();
        else if (islandContainer.restingState === "normal") {
            if (islandContainer.hasCustomLeftItems)
                islandContainer.showCustomCapsule();
            else
                islandContainer.showLyricsCapsule();
        }
        else
            islandContainer.showLyricsCapsule();

        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }

    function swipeLeftWindow() {
        if (islandContainer.restingState === "custom")
            islandContainer.showTimeCapsule();
        else if (islandContainer.restingState === "normal")
            islandContainer.showLyricsCapsule();
        else if (islandContainer.hasCustomLeftItems)
            islandContainer.showCustomCapsule();
        else
            islandContainer.showTimeCapsule();

        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }

    function togglePlayerWindow() {
        if (islandContainer.islandState === "expanded")
            islandContainer.smartRestoreState();
        else
            islandContainer.showExpandedPlayer(false);
    }

    function toggleControlCenterWindow() {
        if (islandContainer.islandState === "control_center")
            islandContainer.smartRestoreState();
        else
            islandContainer.showControlCenter();
    }

    function toggleNotificationCenterWindow() {
        if (islandContainer.islandState === "notification_center")
            islandContainer.smartRestoreState();
        else
            islandContainer.showNotificationCenter();
    }

    function toggleWallpaperPickerWindow() {
        if (islandContainer.islandState === "wallpaper_picker")
            islandContainer.smartRestoreState();
        else
            islandContainer.showWallpaperPicker();
    }

    // --- Demo / testing helpers -------------------------------------------
    // Exposed over IPC (`tide demo*`) so every island activity can be triggered
    // without waiting for a real system event.
    function showToastWindow(icon, text) {
        islandContainer.showToastCapsule(icon, text);
        showAutoHiddenIsland("state");
    }

    function demoNotificationWindow() {
        islandContainer.showNotificationCapsule("Tide", "Screenshot saved", "Screenshot_2026-01-01.png");
        showAutoHiddenIsland("state");
    }

    function demoTimerWindow() {
        islandContainer.toggleTimer(0, 1);
        showAutoHiddenIsland("state");
    }

    function demoMediaWindow() {
        islandContainer.showExpandedPlayer(false);
        showAutoHiddenIsland("state");
    }

    function toggleApplicationLauncherWindow() {
        if (islandContainer.islandState === "application_launcher")
            islandContainer.smartRestoreState();
        else
            islandContainer.showApplicationLauncher();
    }

    onOverviewVisibleChanged: {
        if (overviewVisible && monitorFocused) overviewFocusTimer.restart();
        if (overviewVisible)
            showAutoHiddenIsland("state");
        else
            scheduleAutoHide();
    }
    onConnectivityPromptActiveChanged: {
        if (connectivityPromptActive && monitorFocused)
            connectivityPromptFocusTimer.restart();
        if (connectivityPromptActive)
            showAutoHiddenIsland("state");
        else
            scheduleAutoHide();
    }
    onAutoHideEnabledChanged: {
        if (autoHideEnabled)
            scheduleAutoHide();
        else
            showAutoHiddenIsland("manual");
    }
    onAutoHideCanHideNowChanged: {
        if (autoHideCanHideNow)
            scheduleAutoHide();
        else
            showAutoHiddenIsland("state");
    }
    onOverviewVisualReadyChanged: {
        if (overviewVisualReady) beginOverviewOpening();
    }
    onMonitorFocusedChanged: {
        if (overviewVisible && monitorFocused) overviewFocusTimer.restart();
        if (connectivityPromptActive && monitorFocused) connectivityPromptFocusTimer.restart();
    }

    Timer {
        id: overviewFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: connectivityPromptFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: expandedPlayerFocusTimer
        interval: 0
        repeat: false
        onTriggered: {
            islandContainer.forceActiveFocus();
        }
    }

    Timer {
        id: windowShrinkTimer
        interval: 1000
        repeat: false
        onTriggered: root.retainedWindowHeight = root.requestedWindowHeight
    }

    Timer {
        id: autoHideHideTimer
        interval: Math.max(100, Math.min(10000, userConfig.islandAutoHideDelayMs))
        repeat: false
        onTriggered: root.hideAutoHiddenIsland(false)
    }

    function focusWallpaperPicker() {
        islandContainer.forceActiveFocus();
        if (wallpaperPickerLoader.item && wallpaperPickerLoader.item.grabKeyboardFocus)
            wallpaperPickerLoader.item.grabKeyboardFocus();
    }

    function focusApplicationLauncher() {
        islandContainer.forceActiveFocus();
        if (applicationLauncherLoader.item && applicationLauncherLoader.item.grabKeyboardFocus)
            applicationLauncherLoader.item.grabKeyboardFocus();
    }

    Timer {
        id: overviewRevealTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "opening") root.overviewPhase = "open";
        }
    }

    Timer {
        id: overviewPreloadExpireTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "closed")
                root.overviewPreloading = false;
        }
    }

    Timer {
        id: overviewUnloadGraceTimer
        interval: 260
        repeat: false
    }

    Timer {
        id: wifiConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.wifiConnectivityDetailMounted = false
    }

    Timer {
        id: bluetoothConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.bluetoothConnectivityDetailMounted = false
    }

    OverviewWallpaperCacheController {
        id: overviewWallpaperCache

        active: root.overviewLoaderActive
        wallpaperPath: userConfig.wallpaperCustomCommandEnabled === true && root.wallpaperPickerActiveWallpaper !== ""
            ? root.wallpaperPickerActiveWallpaper
            : userConfig.wallpaperPath
        hyprMonitor: root.hyprMonitor
        screenObject: root.screen
    }

    IslandClock {
        id: timeObj
        clockFormat: userConfig.clockFormat
    }

    // --- 灵动岛主容器与全局状态 ---
    FocusScope {
        id: islandContainer
        anchors.fill: parent
        focus: wallpaperPickerLayerVisible
            || applicationLauncherLayerVisible
            || expandedPlayerKeyboardFocusRequested
            || (root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive))

        property string islandState: "normal"
        property string splitIcon: root.defaultSplitIcon
        property real osdProgress: -1.0
        property bool osdProgressAnimationEnabled: true
        property string osdCustomText: ""
        property int currentWs: root.currentMonitorWorkspaceId > 0 ? root.currentMonitorWorkspaceId : 1
        readonly property int batteryCapacity: systemState.batteryCapacity
        readonly property bool isCharging: systemState.isCharging
        readonly property real currentVolume: systemState.currentVolume
        readonly property bool isMuted: systemState.isMuted
        readonly property real currentBrightness: systemState.currentBrightness
        readonly property real currentCpuUsage: systemState.currentCpuUsage
        readonly property real currentRamUsage: systemState.currentRamUsage
        property string notificationAppName: ""
        property string notificationSummary: ""
        property string notificationBody: ""
        property bool notificationExpanded: false
        property var bluetoothExpandedDevice: null
        property var notificationHistoryModel: ListModel {}
        readonly property var cavaLevels: systemState.cavaLevels
        property real swipeTransitionProgress: 0
        property string workspaceOriginSide: "none"
        property string splitOriginSide: "none"
        property string restingState: "normal"
        property bool expandedByPlayerAutoOpen: false
        property real customCapsuleWidth: root.iosCompactWidth
        property real lyricsCapsuleWidth: root.iosCompactWidth
        property bool sideSwipeSettling: false
        property bool hoverExpandedActive: false
        property bool expandedPlayerKeyboardFocusRequested: false
        property bool openTimerPageWhenExpanded: false
        property int timerSelectedHours: 0
        property int timerSelectedMinutes: 5
        property int timerTotalSeconds: 300
        property int timerRemainingSeconds: 0
        property bool timerRunning: false
        property bool timerActive: false
        property bool timerCompletionAnimating: false
        property real timerCompletionPulse: 0
        property real timerCompletionFlash: 0
        // Life bar for transient activities (notifications, toasts): drains over
        // the auto-hide interval so the island shows how long it will stay.
        property real autoHideLifeProgress: 0
        property bool autoHideLifeVisible: false
        readonly property int autoHideLifeMinimumInterval: 1500

        // --- Interaction / micro-interaction state ------------------------
        // Whole-shape feedback: pressing sinks the capsule, an in-place content
        // update (new track, new glance value) gives it one quick pulse.
        property bool capsulePressed: false
        property real capsulePulse: 0
        // Springs on its own so the press sink shares the shape's motion feel.
        property real pressScaleValue: capsulePressed ? islandMotion.pressScale : 1
        readonly property real interactionScale: pressScaleValue
            * (1 + capsulePulse * (islandMotion.pulseScale - 1))

        Behavior on pressScaleValue {
            SpringAnimation {
                spring: islandMotion.buttonSpring
                damping: islandMotion.buttonDamping
                epsilon: 0.002
            }
        }


        // Transient notifications queue instead of overlapping each other, the
        // way iOS serialises Live Activity alerts.
        property var pendingNotifications: []
        property var queuedNotification: null


        readonly property int defaultAutoHideInterval: 1250
        readonly property int notificationAutoHideInterval: 4200
        readonly property int bluetoothExpandedAutoHideInterval: 2500
        readonly property int swipeAnimationDuration: 220
        readonly property real timerProgress: timerActive && timerTotalSeconds > 0
            ? Math.max(0, Math.min(1, timerRemainingSeconds / timerTotalSeconds))
            : 0
        readonly property bool timerBubbleWanted: (timerActive && timerRemainingSeconds > 0 || timerCompletionAnimating)
            && !root.overviewVisible
            && (islandState === "normal" || islandState === "lyrics" || islandState === "custom"
                || islandState === "live_media")

        // --- Live activities vs. transient content ------------------------
        // A live activity is state tied to something genuinely ongoing (music,
        // a running timer, a recording). While one is alive it *owns* the
        // resting capsule: the island shows its compact view instead of the
        // clock, and it is never dismissed on a timer. Transient content
        // (notifications, OSDs, toasts) briefly overlays the resting state and
        // then collapses back to whatever is live at that moment.
        readonly property bool mediaLive: mediaController.mediaLive
        readonly property bool mediaPlaying: mediaController.mediaPlaying
        readonly property bool timerLive: timerActive && timerRemainingSeconds > 0
        readonly property bool recordingLive: root.screenRecordingActive
        // Deterministic priority: most recently started live activity wins, so
        // music + timer never flicker against each other.
        property int liveActivityOrderCounter: 0
        property int mediaLiveOrder: 0
        property int timerLiveOrder: 0
        property int recordingLiveOrder: 0
        readonly property string activeLiveActivity: {
            let best = "none";
            let bestOrder = 0;
            if (recordingLive && recordingLiveOrder > bestOrder) {
                best = "recording";
                bestOrder = recordingLiveOrder;
            }
            if (timerLive && timerLiveOrder > bestOrder) {
                best = "timer";
                bestOrder = timerLiveOrder;
            }
            if (mediaLive && mediaLiveOrder > bestOrder) {
                best = "media";
                bestOrder = mediaLiveOrder;
            }
            return best;
        }
        readonly property bool liveMediaLayerVisible: !root.overviewVisible && islandState === "live_media"
        readonly property bool liveTimerLayerVisible: !root.overviewVisible && islandState === "live_timer"
        readonly property bool liveDualLayerVisible: !root.overviewVisible && islandState === "live_dual"
        readonly property bool timerExpandedLayerVisible: !root.overviewVisible && islandState === "timer_expanded"

        // Every live activity, most recently started first. Used by the dual
        // (split) compact layout and by the minimal dot's cycling behaviour.
        readonly property var activeLiveActivities: {
            const entries = [];
            if (recordingLive) entries.push({ kind: "recording", order: recordingLiveOrder });
            if (timerLive) entries.push({ kind: "timer", order: timerLiveOrder });
            if (mediaLive) entries.push({ kind: "media", order: mediaLiveOrder });
            entries.sort(function(a, b) { return b.order - a.order; });
            const kinds = [];
            for (let i = 0; i < entries.length; i++)
                kinds.push(entries[i].kind);
            return kinds;
        }
        readonly property int liveActivityCount: activeLiveActivities.length

        // --- Idle (nothing live) ------------------------------------------
        // Idle content is a config value, not a layout decision. Default is the
        // authentic empty, slowly breathing pill.
        IslandIdleConfig { id: idleConfig }

        readonly property string idleContent: idleConfig.idleContent
        readonly property bool idleLayerVisible: !root.overviewVisible && islandState === "normal"
        readonly property bool idleBreathing: idleLayerVisible
            && idleConfig.idleBreathes
            && root.autoHideProgress > 0.99
        // Legacy bar-style clock text inside the swipe layer only survives if
        // the user explicitly asked for the clock idle mode.
        readonly property bool idleShowsClockText: idleConfig.idleShowsClockText
        // Breathing idle draws nothing at all, so the layer is not even mounted.
        readonly property bool idleConfigIsBreathing: idleConfig.idleBreathes


        onMediaLiveChanged: {
            mediaLiveOrder = mediaLive ? ++liveActivityOrderCounter : 0;
            syncLiveActivityResting();
        }
        onTimerLiveChanged: {
            timerLiveOrder = timerLive ? ++liveActivityOrderCounter : 0;
            syncLiveActivityResting();
        }
        onRecordingLiveChanged: {
            recordingLiveOrder = recordingLive ? ++liveActivityOrderCounter : 0;
            syncLiveActivityResting();
        }
        onActiveLiveActivityChanged: syncLiveActivityResting()
        readonly property bool blocksTransientSplit: islandState === "capture_recording"
            || islandState === "capture_screenshot"
            || islandState === "expanded"
            || islandState === "timer_expanded"
            || islandState === "bluetooth_expanded"
            || islandState === "control_center"
            || islandState === "notification"
            || islandState === "wallpaper_picker"
            || islandState === "application_launcher"
        readonly property bool splitShowsProgress: islandState === "split" && osdProgress >= 0
        readonly property bool splitShowsText: islandState === "split" && osdProgress < 0 && osdCustomText !== ""
        readonly property bool splitShowsIconOnly: islandState === "split" && osdProgress < 0 && osdCustomText === ""
        readonly property bool splitUsesExtendedLayout: splitShowsProgress || splitShowsText
        readonly property real splitCapsuleWidth: splitShowsProgress
            ? root.iosCompactWidth * 1.24
            : (splitShowsText ? root.iosCompactWidth : root.islandRestingWidth)
        readonly property bool canShowSideSwipe: islandState === "normal"
            || islandState === "custom"
            || islandState === "lyrics"
            || (islandState === "long_capsule" && workspaceOriginSide === "none")
        readonly property real rightSwipeProgress: Math.max(0, swipeTransitionProgress)
        readonly property var customLeftItems: systemState.customLeftItems
        readonly property bool hasCustomLeftItems: systemState.hasCustomLeftItems
        readonly property bool customSwipeVisible: !root.overviewVisible
            && hasCustomLeftItems
            && (
                capsuleMouseArea.sideSwipeInteractive
                ? swipeTransitionProgress < 0
                : (
                    islandState === "custom"
                    || (islandState === "normal" && swipeTransitionProgress < 0)
                    || (islandState === "split" && splitOriginSide === "left")
                    || (islandState === "long_capsule"
                        && (workspaceOriginSide === "left" || swipeTransitionProgress < 0))
                )
            )
        readonly property bool lyricsSwipeVisible: !root.overviewVisible && (
            capsuleMouseArea.sideSwipeInteractive
            ? swipeTransitionProgress >= 0
            : (
                islandState === "lyrics"
                || (islandState === "normal" && swipeTransitionProgress >= 0)
                || (islandState === "split" && splitOriginSide === "right")
                || (islandState === "long_capsule"
                    && (workspaceOriginSide === "right" || swipeTransitionProgress > 0))
            )
        )
        readonly property bool expandedLayerVisible: !root.overviewVisible && islandState === "expanded"
        readonly property bool bluetoothExpandedLayerVisible: !root.overviewVisible && islandState === "bluetooth_expanded"
        readonly property bool captureRecordingLayerVisible: !root.overviewVisible && islandState === "capture_recording"
        readonly property bool captureScreenshotLayerVisible: !root.overviewVisible && islandState === "capture_screenshot"
        readonly property bool notificationLayerVisible: !root.overviewVisible && islandState === "notification"
        readonly property bool controlCenterLayerVisible: !root.overviewVisible && islandState === "control_center"
        readonly property bool notificationCenterLayerVisible: !root.overviewVisible && islandState === "notification_center"
        readonly property bool wallpaperPickerLayerVisible: !root.overviewVisible && islandState === "wallpaper_picker"
        readonly property bool applicationLauncherLayerVisible: !root.overviewVisible && islandState === "application_launcher"
        readonly property var activePlayer: mediaController.activePlayer
        readonly property string lyricsDisplayText: mediaController.displayText
        readonly property string currentTrack: mediaController.currentTrack
        readonly property string currentArtist: mediaController.currentArtist
        readonly property string currentArtUrl: mediaController.currentArtUrl
        readonly property real trackProgress: mediaController.trackProgress
        readonly property string timePlayed: mediaController.timePlayed
        readonly property string timeTotal: mediaController.timeTotal
        readonly property bool screenRecordingActive: root.screenRecordingActive
        readonly property var bluetoothDevices: bluetoothConnectionTracker.devices
        readonly property var overviewView: overviewLoader.item && overviewLoader.item.overviewView
            ? overviewLoader.item.overviewView
            : null

        onExpandedLayerVisibleChanged: {
            if (!expandedLayerVisible)
                expandedPlayerKeyboardFocusRequested = false;
        }

        onControlCenterLayerVisibleChanged: {
            if (!controlCenterLayerVisible) {
                if (controlCenterLoader.item)
                    controlCenterLoader.item.closeConnectivityPanels();
                else
                    root.closeAllConnectivityDetails();
            }
        }

        onCustomLeftItemsChanged: {
            if (restingState === "custom" && !hasCustomLeftItems) {
                restingState = "normal";

                if (islandState === "custom"
                        || (islandState === "split" && splitOriginSide === "left")
                        || (islandState === "long_capsule" && workspaceOriginSide === "left")) {
                    restoreRestingCapsule(true);
                } else {
                    applyRestingVisuals();
                }
            } else if (restingState === "custom") {
                syncCustomCapsuleWidth();
            }
        }

        IslandMprisController {
            id: mediaController

            expanded: islandContainer.islandState === "expanded"
            clientId: "island-mpris-" + root.screenOutputName
        }

        BluetoothConnectionTracker {
            id: bluetoothConnectionTracker

            onAdapterChanged: islandContainer.bluetoothExpandedDevice = null

            onNewConnection: function(device) {
                islandContainer.showBluetoothExpanded(device);
            }
        }

        IslandSystemState {
            id: systemState

            configuredLeftSwipeItems: userConfig.dynamicIslandLeftSwipeItems
            systemStatsRequired: idleConfig.idleShowsOrb
            timeText: timeObj.currentTime
            dateText: timeObj.currentDateLabel
            currentWorkspace: islandContainer.currentWs
            customSwipeActive: customSwipeLoader.active
            lyricsCavaActive: islandContainer.lyricsSwipeVisible
                && islandContainer.rightSwipeProgress > 0.001

            onTransientRequested: function(icon, progress, text) {
                islandContainer.showTransientCapsule(icon, progress, text);
            }
        }

        CompositorWorkspaceTracker {
            id: workspaceTracker

            compositor: CompositorBackend.compositor
            hyprMonitor: root.hyprMonitor
            hyprMonitorName: root.hyprMonitorName
            outputName: root.compositorOutputName
            monitorFocused: root.monitorFocused

            onWorkspaceSynced: function(workspaceId) {
                islandContainer.currentWs = workspaceId;
            }

            onWorkspaceActivated: function(workspaceId) {
                islandContainer.showWorkspaceCapsule(workspaceId);
            }
        }

        Behavior on osdProgress {
            enabled: islandContainer.osdProgressAnimationEnabled

            SmoothedAnimation { velocity: 1.2; duration: 180; easing.type: Easing.InOutQuad }
        }
        Behavior on swipeTransitionProgress {
            NumberAnimation {
                duration: capsuleMouseArea.sideSwipeInteractive ? 0 : islandContainer.swipeAnimationDuration
                easing.type: Easing.OutCubic
            }
        }

        Keys.onPressed: (event) => {
            if (!root.overviewVisible) return;

            const view = islandContainer.overviewView;
            if (event.key === Qt.Key_H) {
                if (view)
                    view.focusAdjacentWorkspace(0, -1);
                event.accepted = true;
            } else if (event.key === Qt.Key_J) {
                if (view)
                    view.focusAdjacentWorkspace(1, 0);
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                if (view)
                    view.focusAdjacentWorkspace(-1, 0);
                event.accepted = true;
            } else if (event.key === Qt.Key_L) {
                if (view)
                    view.focusAdjacentWorkspace(0, 1);
                event.accepted = true;
            } else if ((event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_Backtab) {
                if (root.hyprlandIntegration)
                    root.hyprlandIntegration.focusWorkspace("r-1");
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                if (root.hyprlandIntegration)
                    root.hyprlandIntegration.focusWorkspace("r+1");
                event.accepted = true;
            }
        }

        function handleConfiguredClickAction(actionName) {
            switch (actionName) {
            case "":
            case "none":
                return;
            case "toggleExpandedPlayer":
                if (islandState === "expanded") {
                    autoHideTimer.stop();
                    smartRestoreState();
                } else {
                    showExpandedPlayer(false);
                }
                return;
            case "openExpandedPlayer":
                showExpandedPlayer(false);
                return;
            case "closeExpandedPlayer":
                if (islandState === "expanded")
                    smartRestoreState();
                return;
            case "toggleNotificationCenter":
                if (islandState === "notification_center")
                    smartRestoreState();
                else
                    showNotificationCenter();
                return;
            case "openNotificationCenter":
                showNotificationCenter();
                return;
            case "closeNotificationCenter":
                if (islandState === "notification_center")
                    smartRestoreState();
                return;
            case "toggleControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                else
                    showControlCenter();
                return;
            case "openControlCenter":
                showControlCenter();
                return;
            case "closeControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                return;
            case "toggleOverview":
                root.toggleOverviewEverywhere();
                return;
            case "openOverview":
                root.openOverviewEverywhere();
                return;
            case "closeOverview":
                root.closeOverviewEverywhere();
                return;
            case "toggleLyrics":
                if (restingState === "lyrics")
                    showTimeCapsule();
                else
                    showLyricsCapsule();
                return;
            case "showLyrics":
                showLyricsCapsule();
                return;
            case "showTime":
                showTimeCapsule();
                return;
            case "restoreRestingCapsule":
                smartRestoreState();
                return;
            default:
            }
        }

        function clamp01(value) {
            return Math.max(0, Math.min(1, value));
        }

        function normalizeRestingState(nextState) {
            if (nextState === "lyrics") return "lyrics";
            if (nextState === "custom" && hasCustomLeftItems) return "custom";
            return "normal";
        }

        // Island state that the active live activity renders in its compact
        // form, or "" when nothing is live.
        function liveActivityState() {
            switch (activeLiveActivity) {
            case "recording":
                return "capture_recording";
            case "timer":
                return "live_timer";
            case "media":
                return "live_media";
            default:
                return "";
            }
        }

        // The single source of truth for "what does the island go back to?".
        // Everything transient collapses to this, never to a hardcoded idle.
        function effectiveRestingState() {
            // Two or more things live at once: the pill carries both as
            // independent compact bubbles instead of hiding one of them.
            if (liveActivityCount > 1)
                return "live_dual";
            const liveState = liveActivityState();
            if (liveState !== "")
                return liveState;
            return normalizeRestingState(restingState);
        }

        function isRestingLikeState(state) {
            return state === "normal"
                || state === "custom"
                || state === "lyrics"
                || state === "live_media"
                || state === "live_timer"
                || state === "live_dual"
                || state === "capture_recording";
        }

        // Re-seat the capsule when a live activity starts or ends. If something
        // transient is on top right now we leave it alone: it re-evaluates the
        // resting state when it collapses, so an activity that ended meanwhile
        // correctly falls through to the clock.
        function syncLiveActivityResting() {
            if (root.overviewVisible) return;
            if (!isRestingLikeState(islandState)) return;
            const target = effectiveRestingState();
            if (islandState === target) return;
            restoreRestingCapsule(true);
        }

        function restingStateProgress(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return -1;
            case "lyrics":
                return 1;
            default:
                return 0;
            }
        }

        function restingStateSide(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            default:
                return "none";
            }
        }

        function swipeRestProgressForState() {
            switch (islandState) {
            case "custom":
                return -1;
            case "lyrics":
                return 1;
            default:
                return 0;
            }
        }

        function currentTransientOriginSide() {
            switch (islandState) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            case "long_capsule":
                return workspaceOriginSide;
            case "split":
                return splitOriginSide;
            default:
                return "none";
            }
        }

        function setOsdProgress(nextProgress, animate) {
            osdProgressAnimationReset.stop();
            osdProgressAnimationEnabled = animate;
            osdProgress = nextProgress;
            if (!animate) osdProgressAnimationReset.restart();
        }

        function abortSideTransientMode() {
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = "none";
            splitOriginSide = "none";
        }

        function clearTransientCapsule() {
            setOsdProgress(-1.0, false);
            osdCustomText = "";
            notificationAppName = "";
            notificationSummary = "";
            notificationBody = "";
            notificationExpanded = false;
            bluetoothExpandedDevice = null;
        }

        function cleanNotificationText(text) {
            return String(text === undefined || text === null ? "" : text)
                .replace(/<[^>]*>/g, " ")
                .replace(/&nbsp;/g, " ")
                .replace(/&amp;/g, "&")
                .replace(/&quot;/g, "\"")
                .replace(/&lt;/g, "<")
                .replace(/&gt;/g, ">")
                .replace(/\s+/g, " ")
                .trim();
        }

        function prepareRestingCapsuleGeometry() {
            if (restingState === "custom")
                syncCustomCapsuleWidth();
            if (restingState === "lyrics")
                syncLyricsCapsuleWidth();
        }

        function applyRestingVisuals() {
            prepareRestingCapsuleGeometry();
            swipeTransitionProgress = restingStateProgress(effectiveRestingState());
        }

        function sideSwipeRestProgressForProgress(progressValue) {
            if (progressValue <= -0.5) return -1;
            if (progressValue >= 0.5) return 1;
            return 0;
        }

        function sideSwipeRestWidthForProgress(progressValue) {
            if (progressValue <= -0.5) return customCapsuleWidth;
            if (progressValue >= 0.5) return lyricsCapsuleWidth;
            return root.islandRestingWidth;
        }

        function customSideSwipeDragDistance() {
            const view = customSwipeLoader.item;
            if (view && view.dragDistance > 0) return view.dragDistance;
            return Math.max(root.islandRestingWidth, customCapsuleWidth + 4);
        }

        function lyricsSideSwipeDragDistance() {
            const view = lyricsSwipeLoader.item;
            if (view && view.dragDistance > 0) return view.dragDistance;
            return Math.max(root.islandRestingWidth, lyricsCapsuleWidth + 2);
        }

        function sideSwipeDragDistanceForDirection(direction) {
            if (direction === "left") return customSideSwipeDragDistance();
            if (direction === "right") return lyricsSideSwipeDragDistance();
            return root.islandRestingWidth;
        }

        function advanceSideSwipeProgress(currentProgress, deltaX) {
            const minProgress = hasCustomLeftItems ? -1 : 0;
            let nextProgress = Math.max(minProgress, Math.min(1, currentProgress));
            let remainingDelta = deltaX;

            if (remainingDelta > 0) {
                if (nextProgress < 0) {
                    const leftDistance = Math.max(1, sideSwipeDragDistanceForDirection("left"));
                    const progressToCenter = Math.min(-nextProgress, remainingDelta / leftDistance);
                    nextProgress += progressToCenter;
                    remainingDelta -= progressToCenter * leftDistance;
                }

                if (remainingDelta > 0 && nextProgress < 1) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    nextProgress = Math.min(1, nextProgress + remainingDelta / rightDistance);
                }
            } else if (remainingDelta < 0) {
                if (nextProgress > 0) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    const progressToCenter = Math.min(nextProgress, -remainingDelta / rightDistance);
                    nextProgress -= progressToCenter;
                    remainingDelta += progressToCenter * rightDistance;
                }

                if (remainingDelta < 0 && nextProgress > minProgress) {
                    const leftDistance = Math.max(1, sideSwipeDragDistanceForDirection("left"));
                    nextProgress = Math.max(minProgress, nextProgress + remainingDelta / leftDistance);
                }
            }

            return Math.max(minProgress, Math.min(1, nextProgress));
        }

        function resolveSideSwipeSettle(startProgress, finalProgress) {
            let settleAction = "";
            let settleProgress = sideSwipeRestProgressForProgress(startProgress);
            let settleWidth = sideSwipeRestWidthForProgress(startProgress);

            if (finalProgress >= 0.56) {
                settleAction = "lyrics";
                settleProgress = 1;
                settleWidth = lyricsCapsuleWidth;
            } else if (hasCustomLeftItems && finalProgress <= -0.56) {
                settleAction = "custom";
                settleProgress = -1;
                settleWidth = customCapsuleWidth;
            } else if (startProgress <= -0.5) {
                if (finalProgress >= -0.44) {
                    settleAction = "time";
                    settleProgress = 0;
                    settleWidth = root.islandRestingWidth;
                }
            } else if (startProgress >= 0.5) {
                if (finalProgress <= 0.44) {
                    settleAction = "time";
                    settleProgress = 0;
                    settleWidth = root.islandRestingWidth;
                }
            } else {
                settleAction = "time";
                settleProgress = 0;
                settleWidth = root.islandRestingWidth;
            }

            return {
                action: settleAction,
                progress: settleProgress,
                width: settleWidth
            };
        }

        function beginSideSwipeSettle(targetWidth) {
            sideSwipeSettling = true;
            mainCapsule.displayedWidth = targetWidth;
            sideSwipeSettleReset.restart();
        }

        function cancelSideSwipeSettle() {
            sideSwipeSettleReset.stop();
            sideSwipeSettling = false;
        }

        function finishSideSwipeSettle() {
            sideSwipeSettling = false;
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
        }

        function restartAutoHideTimer(duration) {
            autoHideTimer.interval = duration === undefined ? defaultAutoHideInterval : duration;
            autoHideTimer.restart();
            startAutoHideLifeBar(autoHideTimer.interval);
        }

        function stopAutoHideTimer() {
            autoHideTimer.stop();
            autoHideTimer.interval = defaultAutoHideInterval;
            stopAutoHideLifeBar();
        }

        function startAutoHideLifeBar(interval) {
            autoHideLifeAnimation.stop();
            autoHideLifeVisible = interval >= autoHideLifeMinimumInterval;
            if (!autoHideLifeVisible) {
                autoHideLifeProgress = 0;
                return;
            }
            autoHideLifeProgress = 1;
            autoHideLifeAnimation.duration = interval;
            autoHideLifeAnimation.start();
        }

        function stopAutoHideLifeBar() {
            autoHideLifeAnimation.stop();
            autoHideLifeVisible = false;
            autoHideLifeProgress = 0;
        }

        // AirPods-style transient toast: icon + short text, auto dismissing.
        function showToastCapsule(icon, text, duration) {
            const interval = duration === undefined ? 2600 : duration;
            showTransientCapsule(icon, text, -1.0);
            restartAutoHideTimer(interval);
        }

        function requestExpandedPlayerKeyboardFocus() {
            const shouldGrabFocus = !expandedPlayerKeyboardFocusRequested;
            expandedPlayerKeyboardFocusRequested = true;
            if (shouldGrabFocus)
                expandedPlayerFocusTimer.restart();
        }

        function releaseExpandedPlayerKeyboardFocus() {
            expandedPlayerKeyboardFocusRequested = false;
        }

        function clampTimerInput(value, minValue, maxValue) {
            const parsed = parseInt(value, 10);
            if (isNaN(parsed)) return minValue;
            return Math.max(minValue, Math.min(maxValue, parsed));
        }

        function syncTimerDuration(hours, minutes) {
            cancelTimerCompletionAnimation();
            timerSelectedHours = clampTimerInput(hours, 0, 23);
            timerSelectedMinutes = clampTimerInput(minutes, 0, 59);
            timerTotalSeconds = timerSelectedHours * 3600 + timerSelectedMinutes * 60;
            timerRemainingSeconds = 0;
            timerRunning = false;
            timerActive = false;
        }

        function toggleTimer(hours, minutes) {
            if (timerCompletionAnimating)
                cancelTimerCompletionAnimation();

            if (timerRunning) {
                timerRunning = false;
                return;
            }

            if (!timerActive || timerRemainingSeconds <= 0) {
                syncTimerDuration(hours, minutes);
                timerRemainingSeconds = timerTotalSeconds;
                timerActive = timerRemainingSeconds > 0;
            }

            if (timerRemainingSeconds > 0)
                timerRunning = true;
        }

        function resetTimer() {
            cancelTimerCompletionAnimation();
            timerRemainingSeconds = 0;
            timerRunning = false;
            timerActive = false;
        }

        function startTimerCompletionAnimation() {
            timerCompletionPulse = 0;
            timerCompletionFlash = 0;
            timerCompletionAnimating = true;
        }

        function cancelTimerCompletionAnimation() {
            timerCompletionAnimating = false;
            timerCompletionPulse = 0;
            timerCompletionFlash = 0;
        }

        function showExpandedTimerPage() {
            openTimerPageWhenExpanded = true;
            showExpandedPlayer(false);
            if (expandedPlayerLoader.item && expandedPlayerLoader.item.openTimerPage) {
                expandedPlayerLoader.item.openTimerPage();
                openTimerPageWhenExpanded = false;
            }
        }

        function showTransientCapsule(icon, progress, customText) {
            if (progress === undefined)    progress = -1.0;
            if (customText === undefined)  customText = "";

            if (root.autoHideSuppressesTransientReveal) return;
            if (blocksTransientSplit) return;

            const nextProgress = progress >= 0 ? progress : -1.0;
            const animateProgress = islandState === "split" && osdProgress >= 0 && nextProgress >= 0;
            const animateFromSide = currentTransientOriginSide();

            abortSideTransientMode();
            splitIcon = icon;
            osdCustomText = customText;
            setOsdProgress(nextProgress, animateProgress);
            splitOriginSide = animateFromSide;
            islandState = "split";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        // One quick whole-shape pulse. Used for in-place content updates (new
        // track, new glance value) that must NOT expand the island.
        function pulseCapsule() {
            capsulePulseAnimation.restart();
        }

        function recordNotificationHistory(appName, summary, body) {
            if (!notificationHistoryModel) return;
            notificationHistoryModel.insert(0, {
                appName: appName,
                summary: summary,
                body: body,
                timestamp: new Date()
            });
            if (notificationHistoryModel.count > 50)
                notificationHistoryModel.remove(50, notificationHistoryModel.count - 50);
        }

        // A transient alert is already on screen: never stack two, queue it.
        function enqueueNotification(entry) {
            const queue = pendingNotifications.slice();
            queue.push(entry);
            if (queue.length > 8)
                queue.splice(0, queue.length - 8);
            pendingNotifications = queue;
        }

        // Called once the current transient alert has collapsed back onto the
        // resting state. Returns true when another alert was started.
        function drainPendingNotification() {
            if (pendingNotifications.length === 0) return false;
            const queue = pendingNotifications.slice();
            queuedNotification = queue.shift();
            pendingNotifications = queue;
            notificationQueueTimer.restart();
            return true;
        }

        function showNotificationCapsule(appName, summary, body) {
            if (root.overviewVisible || islandState === "control_center" || islandState === "expanded") return;

            const cleanedAppName = cleanNotificationText(appName);
            const cleanedSummary = cleanNotificationText(summary);
            const cleanedBody = cleanNotificationText(body);
            const resolvedSummary = cleanedSummary !== ""
                ? cleanedSummary
                : (cleanedBody !== "" ? cleanedBody : "New notification");
            const resolvedAppName = cleanedAppName !== "" ? cleanedAppName : "Notification";
            const resolvedBody = cleanedSummary !== "" ? cleanedBody : "";

            recordNotificationHistory(resolvedAppName, resolvedSummary, resolvedBody);

            // Priority stacking: hold this one until the visible alert is done.
            if (islandState === "notification" || notificationQueueTimer.running) {
                enqueueNotification({
                    appName: resolvedAppName,
                    summary: resolvedSummary,
                    body: resolvedBody
                });
                return;
            }

            abortSideTransientMode();
            clearTransientCapsule();
            notificationAppName = resolvedAppName;
            notificationSummary = resolvedSummary;
            notificationBody = resolvedBody;
            notificationExpanded = false;
            islandState = "notification";
            restartAutoHideTimer(notificationAutoHideInterval);
        }


        function showCaptureRecording() {
            if (root.overviewVisible) return;

            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "capture_recording";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showCaptureScreenshot() {
            if (root.overviewVisible) return;

            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "capture_screenshot";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function toggleNotificationExpansionIfNeeded() {
            if (islandState !== "notification" || !notificationLoader.item || !notificationLoader.item.hasOverflowContent)
                return false;

            if (notificationExpanded) {
                smartRestoreState();
                return true;
            }

            notificationExpanded = true;
            stopAutoHideTimer();
            return true;
        }

        function suppressCapsuleClick(cancelPreparedOverview) {
            if (cancelPreparedOverview === undefined) cancelPreparedOverview = false;
            if (cancelPreparedOverview && capsuleMouseArea.preparedOverviewOnPress) {
                root.cancelPreparedOverviewEverywhere();
                capsuleMouseArea.preparedOverviewOnPress = false;
            }
            capsuleMouseArea.suppressNextClick = true;
            swipeSuppressReset.restart();
        }

        function restoreRestingCapsule(forceImmediate) {
            if (forceImmediate === undefined) forceImmediate = false;
            const normalizedRestingState = effectiveRestingState();
            const targetSide = restingStateSide(normalizedRestingState);
            const shouldAnimateToSide = targetSide !== "none"
                && ((islandState === "long_capsule" && workspaceOriginSide === targetSide)
                    || (islandState === "split" && splitOriginSide === targetSide));

            if (!forceImmediate && shouldAnimateToSide) {
                expandedByPlayerAutoOpen = false;
                prepareRestingCapsuleGeometry();
                swipeTransitionProgress = restingStateProgress(normalizedRestingState);
                stopAutoHideTimer();
                sideTransientRestoreTimer.restart();
                return;
            }

            abortSideTransientMode();
            prepareRestingCapsuleGeometry();
            islandState = normalizedRestingState;
            clearTransientCapsule();
            applyRestingVisuals();
            expandedByPlayerAutoOpen = false;
            stopAutoHideTimer();
        }

        function setRestingState(nextState) {
            restingState = normalizeRestingState(nextState);
        }

        function smartRestoreState() {
            restoreRestingCapsule();
        }

        function showRestingCapsule(nextState) {
            setRestingState(nextState);
            restoreRestingCapsule();
            stopAutoHideTimer();
        }

        function showExpandedPlayer(autoOpened) {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            expandedByPlayerAutoOpen = autoOpened;
            if (autoOpened) restartAutoHideTimer();
            else stopAutoHideTimer();
        }

        // Only compact live activities have a bigger card worth opening; this
        // is what a deliberate long press (or tap toggle) resolves to.
        readonly property bool canExpandRestingActivity: !root.overviewVisible
            && (islandState === "live_media"
                || islandState === "live_timer"
                || islandState === "live_dual")

        // Each activity type has its own expanded layout; nothing shares a
        // generic card.
        function expandActivity(kind) {
            if (root.overviewVisible) return;
            switch (kind) {
            case "timer":
                showTimerExpanded();
                break;
            case "media":
                showExpandedPlayer(false);
                break;
            case "recording":
                // The recording compact state already carries its own controls.
                break;
            default:
                break;
            }
        }

        function expandRestingActivity() {
            if (!canExpandRestingActivity) return;
            if (islandState === "live_timer") {
                showTimerExpanded();
                return;
            }
            if (islandState === "live_dual") {
                // Long-pressing the whole pill expands the primary activity.
                expandActivity(activeLiveActivities.length > 0 ? activeLiveActivities[0] : "");
                return;
            }
            // User-initiated, so never auto-collapse on a timeout.
            showExpandedPlayer(false);
        }

        function showTimerExpanded() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "timer_expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            expandedByPlayerAutoOpen = false;
            stopAutoHideTimer();
        }

        // Tapping the minimal dot rotates which live activities occupy the two
        // compact bubbles: the oldest activity becomes the newest.
        function cycleLiveActivity() {
            if (liveActivityCount < 2) return;
            const last = activeLiveActivities[liveActivityCount - 1];
            liveActivityOrderCounter += 1;
            switch (last) {
            case "media":
                mediaLiveOrder = liveActivityOrderCounter;
                break;
            case "timer":
                timerLiveOrder = liveActivityOrderCounter;
                break;
            case "recording":
                recordingLiveOrder = liveActivityOrderCounter;
                break;
            default:
                break;
            }
        }


        function showBluetoothExpanded(device) {
            if (!device || root.overviewVisible || islandState === "control_center" || islandState === "notification")
                return;

            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            bluetoothExpandedDevice = device;
            islandState = "bluetooth_expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            expandedByPlayerAutoOpen = false;
            restartAutoHideTimer(bluetoothExpandedAutoHideInterval);
        }

        function showControlCenter() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "control_center";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showNotificationCenter() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "notification_center";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }


        function showWallpaperPicker() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "wallpaper_picker";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showApplicationLauncher() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "application_launcher";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showCustomCapsule() {
            if (!hasCustomLeftItems) {
                showTimeCapsule();
                return;
            }

            systemState.refreshMissingValues();
            showRestingCapsule("custom");
        }

        function showLyricsCapsule() {
            showRestingCapsule("lyrics");
        }

        function showTimeCapsule() {
            showRestingCapsule("normal");
        }

        function showWorkspaceCapsule(wsId) {
            currentWs = wsId;
            if (root.autoHideSuppressesTransientReveal) return;
            if (islandState === "control_center" || islandState === "notification") return;
            const animateFromSide = currentTransientOriginSide();
            clearTransientCapsule();
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = animateFromSide;
            splitOriginSide = "none";
            islandState = "long_capsule";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        Timer {
            id: autoHideTimer

            interval: islandContainer.defaultAutoHideInterval
            onTriggered: {
                const wasNotification = islandContainer.islandState === "notification";
                islandContainer.smartRestoreState();
                if (wasNotification)
                    islandContainer.drainPendingNotification();
            }
        }

        // Queued alerts wait for the capsule to settle back onto the resting
        // state before the next one takes over, so two alerts never overlap.
        Timer {
            id: notificationQueueTimer

            interval: islandMotion.settleDuration + 120
            repeat: false
            onTriggered: {
                const entry = islandContainer.queuedNotification;
                islandContainer.queuedNotification = null;
                if (!entry) return;
                if (root.overviewVisible
                        || islandContainer.islandState === "control_center"
                        || islandContainer.islandState === "expanded") {
                    return;
                }

                islandContainer.abortSideTransientMode();
                islandContainer.clearTransientCapsule();
                islandContainer.notificationAppName = entry.appName;
                islandContainer.notificationSummary = entry.summary;
                islandContainer.notificationBody = entry.body;
                islandContainer.notificationExpanded = false;
                islandContainer.islandState = "notification";
                islandContainer.restartAutoHideTimer(islandContainer.notificationAutoHideInterval);
            }
        }

        // Single quick acknowledgement pulse — same spring family as the morph.
        SequentialAnimation {
            id: capsulePulseAnimation

            NumberAnimation {
                target: islandContainer
                property: "capsulePulse"
                to: 1
                duration: islandMotion.pulseAttackDuration
                easing.type: Easing.OutCubic
            }

            SpringAnimation {
                target: islandContainer
                property: "capsulePulse"
                to: 0
                spring: islandMotion.shapeSpring
                damping: islandMotion.shapeDamping
                mass: islandMotion.shapeMass
                epsilon: 0.01
            }
        }


        NumberAnimation {
            id: autoHideLifeAnimation

            target: islandContainer
            property: "autoHideLifeProgress"
            to: 0
            easing.type: Easing.Linear
        }
        Timer {
            id: islandTimerTick
            interval: 1000
            repeat: true
            running: islandContainer.timerRunning
            onTriggered: {
                const nextRemainingSeconds = Math.max(0, islandContainer.timerRemainingSeconds - 1);
                if (nextRemainingSeconds <= 0) {
                    islandContainer.startTimerCompletionAnimation();
                    islandContainer.timerRemainingSeconds = 0;
                    islandContainer.timerRunning = false;
                    islandContainer.timerActive = false;
                } else {
                    islandContainer.timerRemainingSeconds = nextRemainingSeconds;
                }
            }
        }
        Timer {
            id: osdProgressAnimationReset
            interval: 0
            onTriggered: islandContainer.osdProgressAnimationEnabled = true
        }
        Timer {
            id: sideTransientRestoreTimer
            interval: islandContainer.swipeAnimationDuration
            onTriggered: {
                islandContainer.workspaceOriginSide = "none";
                islandContainer.splitOriginSide = "none";
                islandContainer.prepareRestingCapsuleGeometry();
                islandContainer.islandState = islandContainer.effectiveRestingState();
                islandContainer.clearTransientCapsule();
                islandContainer.applyRestingVisuals();
                islandContainer.expandedByPlayerAutoOpen = false;
            }
        }
        Timer {
            id: sideSwipeSettleReset
            interval: mainCapsule.morphDuration
            onTriggered: islandContainer.finishSideSwipeSettle()
        }
        Timer {
            id: hoverExpandDelayTimer
            interval: 350
            repeat: false
            onTriggered: {
                if (!capsuleMouseArea.containsMouse) return;
                if (!root.hoverExpandEnabled) return;

                const current = islandContainer.islandState;
                const target = root.configuredHoverExpandAction === 2 ? "control_center" : "expanded";
                if (current === target) return;
                if (current !== "normal" && current !== "custom" && current !== "lyrics"
                        && current !== "live_media" && current !== "live_timer")
                    return;

                islandContainer.hoverExpandedActive = true;
                if (root.configuredHoverExpandAction === 2)
                    islandContainer.showControlCenter();
                else
                    islandContainer.showExpandedPlayer(false);
            }
        }
        Timer {
            id: hoverCollapseDelayTimer
            interval: 250
            repeat: false
            onTriggered: {
                if (capsuleMouseArea.containsMouse) return;
                if (!islandContainer.hoverExpandedActive) return;
                islandContainer.hoverExpandedActive = false;
                islandContainer.smartRestoreState();
            }
        }

        function syncCustomCapsuleWidth() {
            const view = customSwipeLoader.item;
            if (!view) return;
            customCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        function syncLyricsCapsuleWidth() {
            const view = lyricsSwipeLoader.item;
            if (!view) return;
            lyricsCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        // Ongoing media is never a reason to expand. A new track while the
        // compact pill is already up is acknowledged in place: the layer
        // cross-fades its art and the capsule gives one quick pulse.
        onCurrentTrackChanged: {
            if (currentTrack === "") return;
            if (root.autoHideSuppressesTransientReveal) return;
            if (islandState !== "live_media") return;
            pulseCapsule();
        }


        // macOS notch shoulders: the concave fillets that blend the notch into
        // the surrounding bezel, drawn in the capsule colour on both sides.
        Component {
            id: notchShoulderComponent

            Canvas {
                property bool mirrored: false
                property color fillColor: "#000000"

                onFillColorChanged: requestPaint()
                onMirroredChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = fillColor;
                    ctx.beginPath();
                    if (mirrored) {
                        // Left shoulder: fill everything except a quarter disc
                        // centred on the outer bottom corner.
                        ctx.moveTo(width, 0);
                        ctx.lineTo(0, 0);
                        ctx.arc(0, height, width, -Math.PI / 2, 0, false);
                        ctx.lineTo(width, 0);
                    } else {
                        ctx.moveTo(0, 0);
                        ctx.lineTo(0, height);
                        ctx.arc(width, height, width, Math.PI, Math.PI * 1.5, false);
                        ctx.lineTo(0, 0);
                    }
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }

        Loader {
            id: leftShoulder

            z: 5
            sourceComponent: notchShoulderComponent
            active: root.notchChromeVisible
            visible: root.notchChromeVisible && mainCapsule.opacity > 0.01
            opacity: mainCapsule.opacity
            width: root.macNotchShoulder
            height: root.macNotchShoulder
            x: mainCapsule.x - width
            y: mainCapsule.y
            onLoaded: {
                item.mirrored = true;
                item.fillColor = mainCapsule.color;
            }
        }

        Loader {
            id: rightShoulder

            z: 5
            sourceComponent: notchShoulderComponent
            active: root.notchChromeVisible
            visible: root.notchChromeVisible && mainCapsule.opacity > 0.01
            opacity: mainCapsule.opacity
            width: root.macNotchShoulder
            height: root.macNotchShoulder
            x: mainCapsule.x + mainCapsule.width
            y: mainCapsule.y
            onLoaded: {
                item.mirrored = false;
                item.fillColor = mainCapsule.color;
            }
        }

        Connections {
            target: mainCapsule
            function onColorChanged() {
                if (leftShoulder.item) leftShoulder.item.fillColor = mainCapsule.color;
                if (rightShoulder.item) rightShoulder.item.fillColor = mainCapsule.color;
            }
        }

        // Shared motion tokens for every island animation.
        IslandMotion { id: islandMotion }

        // Soft ambient shadow so the capsule reads as a physical object floating
        // over the desktop. Skipped in notch mode, where the shape is welded to
        // the top bezel and a shadow would look like a rendering artefact.
        Repeater {
            model: 3

            Rectangle {
                required property int index

                readonly property real spread: (index + 1) * 3

                z: 4
                x: mainCapsule.x - spread
                y: mainCapsule.y + spread * 0.6
                width: mainCapsule.width + spread * 2
                height: mainCapsule.height + spread * 0.8
                radius: mainCapsule.radius + spread
                color: "transparent"
                border.width: spread
                border.color: Qt.rgba(0, 0, 0, 0.10 - index * 0.025)
                opacity: mainCapsule.opacity * 0.9
                visible: !root.overviewContentVisible
            }
        }

        // --- UI 渲染：灵动岛主干 ---
        Rectangle {
            id: mainCapsule
            z: 5

            property int morphDuration: islandMotion.settleDuration
            readonly property bool notificationHistorySurface: islandContainer.islandState === "notification_center"
            property real outlineWidth: root.overviewContentVisible || notificationHistorySurface ? 1 : 0
            property color outlineColor: root.overviewContentVisible
                ? root.overviewCapsuleBorderColor
                : (notificationHistorySurface ? "#1affffff" : StyleTokens.clearBlack)
            property real displayedWidth: baseTargetWidth
            readonly property real baseTargetWidth: {
                if (root.overviewVisible) return root.overviewCapsuleWidth;
                if (sideTransientRestoreTimer.running) {
                    if (islandContainer.restingState === "lyrics"
                            && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "right")
                                || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "right"))) {
                        return islandContainer.lyricsCapsuleWidth;
                    }

                    if (islandContainer.restingState === "custom"
                            && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "left")
                                || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "left"))) {
                        return islandContainer.customCapsuleWidth;
                    }
                }

                switch (islandContainer.islandState) {
                case "capture_recording":
                    // Reference metric from the approved iOS mock: 340 x 92.
                    return Math.max(root.islandRestingWidth, root.iosRecordingWidth);
                case "capture_screenshot":
                    return root.iosShotWidth;
                case "split":
                    return islandContainer.splitCapsuleWidth;
                case "long_capsule":
                    return root.iosCompactWidth;
                case "live_media":
                    return Math.max(root.islandRestingWidth, root.iosCompactWidth * 1.1);
                case "live_dual":
                    // Room for two bubbles plus the middle gap.
                    return Math.max(root.islandRestingWidth, root.iosCompactWidth * 1.5);
                case "timer_expanded":
                    return root.iosExpandedWidth;
                case "live_timer":
                    return Math.max(root.islandRestingWidth, root.iosCompactWidth * 0.78);
                case "custom":
                    return islandContainer.customCapsuleWidth;
                case "lyrics":
                    return islandContainer.lyricsCapsuleWidth;
                case "control_center":
                    return root.iosControlWidth;
                case "notification_center":
                    return root.iosExpandedWidth;
                case "wallpaper_picker":
                case "application_launcher":
                    return 1100;
                case "expanded":
                case "bluetooth_expanded":
                    return root.iosExpandedWidth;
                case "notification":
                    if (!notificationLoader.item) return root.iosCompactWidth;
                    return Math.max(
                        notificationLoader.item.minimumWidth,
                        Math.min(root.width - 48, notificationLoader.item.maximumWidth, notificationLoader.item.preferredWidth)
                    );
                default:
                    return root.islandRestingWidth;
                }
            }
            readonly property real targetHeight: {
                if (root.overviewVisible) return root.overviewCapsuleHeight;

                switch (islandContainer.islandState) {
                case "capture_screenshot":
                    return root.iosShotHeight;
                case "capture_recording":
                    return root.iosRecordingHeight;
                case "control_center":
                    return root.iosControlHeight;
                case "notification_center":
                    return notificationCenterLoader.item ? notificationCenterLoader.item.contentHeight : 200;
                case "wallpaper_picker":
                case "application_launcher":
                    return 260;
                case "expanded":
                case "bluetooth_expanded":
                    return root.iosExpandedHeight;
                case "timer_expanded":
                    // Shorter than the media card: one hero countdown and two
                    // small controls, no scrubber or transport row.
                    return Math.max(104, root.iosExpandedHeight * 0.76);
                case "notification":
                    return notificationLoader.item
                        ? Math.max(root.iosNotificationHeight, notificationLoader.item.preferredHeight)
                        : root.iosNotificationHeight;
                default:
                    return root.islandRestingHeight;
                }
            }
            // One shape, one radius rule: perfect pill while the capsule is
            // small, easing toward a rounded-card radius as it grows. Because it
            // is derived from the live height, the corners stay correct at every
            // frame of the morph instead of being animated separately.
            readonly property real targetRadius: {
                if (root.overviewVisible) return root.overviewCapsuleRadius;
                return root.capsuleRadiusForHeight(mainCapsule.targetHeight);
            }

            function sideSwipeWidthForProgress(progressValue) {
                if (progressValue < 0)
                    return root.islandRestingWidth + (islandContainer.customCapsuleWidth - root.islandRestingWidth)
                        * islandContainer.clamp01(-progressValue);
                if (progressValue > 0)
                    return root.islandRestingWidth + (islandContainer.lyricsCapsuleWidth - root.islandRestingWidth)
                        * islandContainer.clamp01(progressValue);
                return root.islandRestingWidth;
            }
            readonly property real sideSwipePreviewWidth: mainCapsule.sideSwipeWidthForProgress(
                islandContainer.swipeTransitionProgress
            )
            color: root.overviewContentVisible
                ? root.overviewCapsuleColor
                : (notificationHistorySurface ? "#080808" : Qt.rgba(0, 0, 0, userConfig.islandBackgroundOpacity / 100.0))
            y: root.islandTopOffset
                - (1 - root.autoHideProgress) * (targetHeight + root.islandTopOffset + 8)
            x: parent
                ? Math.round(
                    root.macNotchStyle
                        ? (parent.width - width) / 2
                        : parent.width * userConfig.islandPositionX / 100 - width / 2
                )
                : 0
            clip: true
            width: displayedWidth
            height: targetHeight
            // Derived from the *live* height, so the corners are never out of
            // sync with the shape while it springs. No radius animation needed.
            radius: root.overviewVisible
                ? Math.min(root.overviewCapsuleRadius, height / 2)
                : root.capsuleRadiusForHeight(height)

            // Idle breath: a barely perceptible several-second loop that only
            // runs while the island is genuinely idle and fully shown.
            property real idleBreathScale: 1
            property real idleBreathOpacity: 1

            opacity: root.autoHideProgress * idleBreathOpacity
            scale: (0.96 + root.autoHideProgress * 0.04)
                * islandContainer.interactionScale
                * idleBreathScale
            transformOrigin: Item.Top

            SequentialAnimation {
                id: idleBreathAnimation

                running: islandContainer.idleBreathing
                loops: Animation.Infinite
                alwaysRunToEnd: false

                ParallelAnimation {
                    NumberAnimation {
                        target: mainCapsule
                        property: "idleBreathScale"
                        to: islandMotion.idleBreathScale
                        duration: islandMotion.idleBreathDuration
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: mainCapsule
                        property: "idleBreathOpacity"
                        to: islandMotion.idleBreathOpacity
                        duration: islandMotion.idleBreathDuration
                        easing.type: Easing.InOutSine
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: mainCapsule
                        property: "idleBreathScale"
                        to: 1
                        duration: islandMotion.idleBreathDuration
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: mainCapsule
                        property: "idleBreathOpacity"
                        to: 1
                        duration: islandMotion.idleBreathDuration
                        easing.type: Easing.InOutSine
                    }
                }

                onRunningChanged: {
                    if (running) return;
                    idleBreathSettle.restart();
                }
            }

            NumberAnimation {
                id: idleBreathSettle

                target: mainCapsule
                properties: "idleBreathScale,idleBreathOpacity"
                to: 1
                duration: 220
                easing.type: Easing.OutCubic
            }


            // macOS notch: square off the two top corners so the capsule is
            // welded to the top bezel instead of floating like the iOS pill.
            Rectangle {
                visible: root.notchChromeVisible && mainCapsule.radius > 0
                color: mainCapsule.color
                width: mainCapsule.radius
                height: mainCapsule.radius
                anchors.top: parent.top
                anchors.left: parent.left
                z: 0
            }
            Rectangle {
                visible: root.notchChromeVisible && mainCapsule.radius > 0
                color: mainCapsule.color
                width: mainCapsule.radius
                height: mainCapsule.radius
                anchors.top: parent.top
                anchors.right: parent.right
                z: 0
            }

            // Very subtle top-down sheen. Kept as an overlay instead of a
            // gradient on the capsule itself so `color` (and its animation)
            // stays intact for the notch shoulders that mirror it.
            Rectangle {
                anchors.fill: parent
                z: 0
                radius: parent.radius
                opacity: root.overviewContentVisible ? 0 : 1
                visible: opacity > 0.001
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#12ffffff" }
                    GradientStop { position: 0.45; color: "#04ffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
            }

            // Transient activity life bar, hugging the bottom edge.
            Rectangle {
                id: autoHideLifeBar

                z: 2
                height: 2
                radius: 1
                color: "#66ffffff"
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.max(3, parent.radius * 0.18)
                anchors.left: parent.left
                anchors.leftMargin: Math.max(10, parent.radius * 0.7)
                width: Math.max(0, (parent.width - anchors.leftMargin * 2)
                    * islandContainer.autoHideLifeProgress)
                opacity: islandContainer.autoHideLifeVisible && !root.overviewContentVisible ? 1 : 0
                visible: opacity > 0.001 && width > 0.5

                Behavior on opacity {
                    NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
                }
            }

            onBaseTargetWidthChanged: {
                if (!capsuleMouseArea.sideSwipeInteractive && !islandContainer.sideSwipeSettling)
                    displayedWidth = baseTargetWidth;
            }

            // Springs, not curves: the island's settle is distance dependent
            // with a small overshoot, which is what makes it feel like a single
            // blob of matter rather than a resizing rectangle.
            Behavior on displayedWidth {
                enabled: !capsuleMouseArea.sideSwipeInteractive

                SpringAnimation {
                    spring: islandMotion.shapeSpring
                    damping: islandMotion.shapeDamping
                    mass: islandMotion.shapeMass
                    epsilon: islandMotion.shapeEpsilon
                }
            }
            Behavior on height {
                enabled: !(controlCenterLoader.item && controlCenterLoader.item.batteryDrawerMoving)

                SpringAnimation {
                    spring: islandMotion.shapeSpring
                    damping: islandMotion.shapeDamping
                    mass: islandMotion.shapeMass
                    epsilon: islandMotion.shapeEpsilon
                }
            }

            Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.InOutQuad } }
            Behavior on outlineWidth { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on outlineColor { ColorAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            border.width: outlineWidth
            border.color: outlineColor

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(parent.radius - 1, 0)
                color: StyleTokens.transparent
                border.width: 1
                border.color: StyleTokens.overviewInnerBorder
                opacity: root.overviewContentVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.overviewContentVisible ? 260 : 140
                        easing.type: Easing.InOutQuad
                    }
                }
            }


            MouseArea {
                id: capsuleMouseArea
                anchors.fill: parent
                z: -1
                enabled: !root.overviewVisible && twoFingerTouchArea.touchPoints.length < 2
                acceptedButtons: root.dynamicIslandAcceptedButtons
                preventStealing: true
                hoverEnabled: root.hoverExpandEnabled || root.autoHideEnabled
                property real swipeStartX: 0
                property real swipeStartY: 0
                property real swipeStartProgress: 0
                property real swipeLastX: 0
                readonly property real sideSwipeVerticalTolerance: 24
                property bool swipeArmed: false
                property bool swipeMoved: false
                property bool sideSwipeInteractive: false
                property bool suppressNextClick: false
                property bool preparedOverviewOnPress: false

                property bool longPressTriggered: false

                Timer {
                    id: swipeSuppressReset
                    interval: 180
                    repeat: false
                    onTriggered: capsuleMouseArea.suppressNextClick = false
                }

                // Short click = compact peek / configured action.
                // Long press  = go straight to the full expanded card.
                Timer {
                    id: longPressTimer

                    interval: islandMotion.longPressInterval
                    repeat: false
                    onTriggered: {
                        if (capsuleMouseArea.swipeMoved) return;
                        capsuleMouseArea.longPressTriggered = true;
                        islandContainer.expandRestingActivity();
                    }
                }


                onEntered: {
                    if (root.autoHideEnabled) {
                        root.autoHidePointerInside = true;
                        root.showAutoHiddenIsland();
                    }
                    if (root.hoverExpandEnabled) {
                        hoverCollapseDelayTimer.stop();
                        hoverExpandDelayTimer.restart();
                    }
                }

                onExited: {
                    if (root.autoHideEnabled) {
                        root.autoHidePointerInside = false;
                        root.scheduleAutoHide();
                    }
                    if (root.hoverExpandEnabled)
                        hoverCollapseDelayTimer.restart();
                }

                onPressed: (mouse) => {
                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    swipeStartX = mappedPoint.x;
                    swipeStartY = mappedPoint.y;
                    islandContainer.cancelSideSwipeSettle();
                    swipeArmed = mouse.button === Qt.LeftButton
                        && islandContainer.canShowSideSwipe;
                    swipeStartProgress = islandContainer.swipeTransitionProgress;
                    swipeLastX = mappedPoint.x;
                    swipeMoved = false;
                    sideSwipeInteractive = swipeArmed;
                    islandContainer.swipeTransitionProgress = swipeStartProgress;

                    // Whole-shape press feedback, plus long-press arming.
                    islandContainer.capsulePressed = true;
                    longPressTriggered = false;
                    if (mouse.button === Qt.LeftButton && islandContainer.canExpandRestingActivity)
                        longPressTimer.restart();


                    let pressedAction = "";
                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                        pressedAction = userConfig.dynamicIslandPrimaryAction;
                    } else if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                        pressedAction = userConfig.dynamicIslandSecondaryAction;
                    }

                    preparedOverviewOnPress = pressedAction === "openOverview"
                        || (pressedAction === "toggleOverview" && root.overviewPhase === "closed");
                    if (preparedOverviewOnPress)
                        root.prepareOverviewEverywhere();
                }

                onPositionChanged: (mouse) => {
                    if (!pressed || !swipeArmed || suppressNextClick || twoFingerTouchArea.touchPoints.length >= 2) return;

                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    const deltaX = mappedPoint.x - swipeLastX;
                    const deltaY = Math.abs(mappedPoint.y - swipeStartY);
                    const adjustedDeltaX = deltaY < sideSwipeVerticalTolerance ? deltaX : 0;
                    const nextProgress = islandContainer.advanceSideSwipeProgress(
                        islandContainer.swipeTransitionProgress,
                        adjustedDeltaX
                    );

                    swipeMoved = swipeMoved || Math.abs(nextProgress - swipeStartProgress) > 0.03 || deltaY > 6;
                    if (swipeMoved)
                        longPressTimer.stop();
                    swipeLastX = mappedPoint.x;
                    islandContainer.swipeTransitionProgress = nextProgress;
                    mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;

                }

                onReleased: {
                    islandContainer.capsulePressed = false;
                    longPressTimer.stop();
                    if (longPressTriggered) {
                        // The long press already acted; swallow the click.
                        suppressNextClick = true;
                        swipeSuppressReset.restart();
                    }
                    if (swipeMoved) {

                        if (preparedOverviewOnPress)
                            root.cancelPreparedOverviewEverywhere();
                        preparedOverviewOnPress = false;
                        suppressNextClick = true;
                        swipeSuppressReset.restart();
                    }
                    let settleResult = {
                        action: "",
                        progress: islandContainer.sideSwipeRestProgressForProgress(swipeStartProgress),
                        width: islandContainer.sideSwipeRestWidthForProgress(swipeStartProgress)
                    };

                    if (swipeArmed)
                        settleResult = islandContainer.resolveSideSwipeSettle(
                            swipeStartProgress,
                            islandContainer.swipeTransitionProgress
                        );

                    sideSwipeInteractive = false;

                    if (swipeArmed)
                        islandContainer.beginSideSwipeSettle(settleResult.width);
                    else
                        mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;

                    if (swipeArmed) {
                        switch (settleResult.action) {
                        case "time":
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.showCustomCapsule();
                            break;
                        case "lyrics":
                            islandContainer.showLyricsCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    } else {
                        islandContainer.swipeTransitionProgress = settleResult.progress;
                    }
                    swipeArmed = false;
                    swipeMoved = false;
                }

                onCanceled: {
                    islandContainer.capsulePressed = false;
                    longPressTimer.stop();
                    longPressTriggered = false;
                    if (preparedOverviewOnPress)
                        root.cancelPreparedOverviewEverywhere();
                    swipeArmed = false;

                    swipeMoved = false;
                    sideSwipeInteractive = false;
                    suppressNextClick = false;
                    preparedOverviewOnPress = false;
                    swipeSuppressReset.stop();
                    mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
                    islandContainer.swipeTransitionProgress = islandContainer.swipeRestProgressForState();
                }

                onClicked: (mouse) => {
                    islandContainer.hoverExpandedActive = false;
                    hoverExpandDelayTimer.stop();
                    hoverCollapseDelayTimer.stop();

                    if (suppressNextClick) {
                        swipeSuppressReset.stop();
                        suppressNextClick = false;
                        preparedOverviewOnPress = false;
                        return;
                    }

                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                        if (islandContainer.toggleNotificationExpansionIfNeeded()) {
                            if (preparedOverviewOnPress)
                                root.cancelPreparedOverviewEverywhere();
                            preparedOverviewOnPress = false;
                            return;
                        }

                        preparedOverviewOnPress = false;
                        islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandPrimaryAction);
                        return;
                    }

                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                        preparedOverviewOnPress = false;
                        islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandSecondaryAction);
                    }
                }
            }

            MultiPointTouchArea {
                id: twoFingerTouchArea
                anchors.fill: parent
                z: 0
                enabled: !root.overviewVisible
                mouseEnabled: false
                minimumTouchPoints: 2
                maximumTouchPoints: 2

                property real swipeStartX: 0
                property real swipeStartProgress: 0
                property bool swipeMoved: false

                onPressed: (touchPoints) => {
                    const centerPoint = islandContainer.mapFromItem(twoFingerTouchArea, 
                        (touchPoints[0].x + touchPoints[1].x) / 2,
                        (touchPoints[0].y + touchPoints[1].y) / 2);
                    swipeStartX = centerPoint.x;
                    swipeStartProgress = islandContainer.swipeTransitionProgress;
                    swipeMoved = false;
                    islandContainer.cancelSideSwipeSettle();
                }

                onUpdated: (touchPoints) => {
                    const centerPoint = islandContainer.mapFromItem(twoFingerTouchArea, 
                        (touchPoints[0].x + touchPoints[1].x) / 2,
                        (touchPoints[0].y + touchPoints[1].y) / 2);
                    
                    const deltaX = centerPoint.x - swipeStartX;
                    const nextProgress = islandContainer.advanceSideSwipeProgress(
                        swipeStartProgress,
                        deltaX
                    );

                    if (Math.abs(nextProgress - swipeStartProgress) > 0.03) {
                        swipeMoved = true;
                    }

                    islandContainer.swipeTransitionProgress = nextProgress;
                    mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;
                }

                onReleased: {
                    if (swipeMoved) {
                        const settleResult = islandContainer.resolveSideSwipeSettle(
                            swipeStartProgress,
                            islandContainer.swipeTransitionProgress
                        );

                        islandContainer.beginSideSwipeSettle(settleResult.width);

                        switch (settleResult.action) {
                        case "time":
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.showCustomCapsule();
                            break;
                        case "lyrics":
                            islandContainer.showLyricsCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    } else {
                        islandContainer.swipeTransitionProgress = islandContainer.sideSwipeRestProgressForProgress(swipeStartProgress);
                    }
                    swipeMoved = false;
                }
            }



            Loader {
                id: customSwipeLoader
                anchors.fill: parent
                active: islandContainer.customSwipeVisible
                asynchronous: false
                visible: active

                onLoaded: islandContainer.syncCustomCapsuleWidth()

                sourceComponent: Component {
                    SwipeCustomInfoLayer {
                        items: islandContainer.customLeftItems
                        cavaLevels: islandContainer.cavaLevels
                        timeText: timeObj.currentTime
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.heroFontFamily
                        timeFontFamily: root.heroFontFamily
                        textPixelSize: root.bodyFontSize
                        iconPixelSize: root.iconFontSize
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.swipeTransitionProgress
                        recordingActive: islandContainer.screenRecordingActive
                        showSecondaryText: islandContainer.workspaceOriginSide !== "left"
                            && islandContainer.splitOriginSide !== "left"
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncCustomCapsuleWidth()
                    }
                }
            }

            Loader {
                id: lyricsSwipeLoader
                anchors.fill: parent
                active: islandContainer.lyricsSwipeVisible
                asynchronous: false
                visible: active

                onLoaded: islandContainer.syncLyricsCapsuleWidth()

                sourceComponent: Component {
                    SwipeLyricsLayer {
                        lyricText: islandContainer.lyricsDisplayText
                        currentArtUrl: islandContainer.currentArtUrl
                        cavaLevels: islandContainer.cavaLevels
                        timeText: timeObj.currentTime
                        textFontFamily: root.textFontFamily
                        timeFontFamily: root.timeFontFamily
                        textPixelSize: root.bodyFontSize
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.rightSwipeProgress
                        recordingActive: islandContainer.screenRecordingActive
                        // The idle capsule no longer carries a bar-style clock:
                        // idle content is owned by IslandIdleLayer and is empty
                        // unless the "clock" idle mode is configured.
                        showSecondaryText: islandContainer.workspaceOriginSide !== "right"
                            && islandContainer.splitOriginSide !== "right"
                            && islandContainer.idleShowsClockText
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncLyricsCapsuleWidth()
                    }
                }
            }

            Loader {
                id: splitIconLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitShowsIconOnly
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    SplitIconLayer {
                        iconText: islandContainer.splitIcon
                        iconFontFamily: root.iconFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }
                }
            }

            Loader {
                id: osdLayerLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitUsesExtendedLayout
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    OsdLayer {
                        iconText: islandContainer.splitIcon
                        progress: islandContainer.osdProgress
                        customText: islandContainer.osdCustomText
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }
                }
            }

            Loader {
                id: workspaceLayerLoader
                anchors.fill: parent
                active: !root.overviewVisible
                    && islandContainer.islandState === "long_capsule"
                    && (islandContainer.workspaceOriginSide !== "none"
                        || Math.abs(islandContainer.swipeTransitionProgress) < 0.001)
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    WorkspaceLayer {
                        workspaceId: islandContainer.currentWs
                        displayText: "Workspace " + islandContainer.currentWs
                        textFontFamily: root.textFontFamily
                        textPixelSize: root.bodyFontSize
                        animateVisibility: islandContainer.restingState === "normal"
                        transitionProgress: islandContainer.swipeTransitionProgress
                        showCondition: true
                        slideDirection: islandContainer.workspaceOriginSide
                    }
                }
            }

            Loader {
                id: idleLoader

                anchors.fill: parent
                active: islandContainer.idleLayerVisible && !islandContainer.idleConfigIsBreathing
                asynchronous: false
                sourceComponent: IslandIdleLayer {
                    idleContent: islandContainer.idleContent
                    cpuUsage: islandContainer.currentCpuUsage
                    ramUsage: islandContainer.currentRamUsage
                    currentTime: timeObj.currentTime
                    textFontFamily: root.textFontFamily
                    showCondition: islandContainer.idleLayerVisible
                }
            }


            Loader {
                id: liveMediaLoader
                anchors.fill: parent
                active: islandContainer.liveMediaLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    LiveMediaLayer {
                        currentArtUrl: islandContainer.currentArtUrl
                        currentTrack: islandContainer.currentTrack
                        currentArtist: islandContainer.currentArtist
                        playing: islandContainer.mediaPlaying
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.liveMediaLayerVisible
                    }
                }
            }

            Loader {
                id: liveTimerLoader
                anchors.fill: parent
                active: islandContainer.liveTimerLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    LiveTimerLayer {
                        progress: islandContainer.timerProgress
                        remainingSeconds: islandContainer.timerRemainingSeconds
                        running: islandContainer.timerRunning
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.liveTimerLayerVisible
                    }
                }
            }

            Loader {
                id: liveDualLoader
                anchors.fill: parent
                active: islandContainer.liveDualLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    LiveDualLayer {
                        activities: islandContainer.activeLiveActivities
                        currentArtUrl: islandContainer.currentArtUrl
                        mediaPlaying: islandContainer.mediaPlaying
                        timerProgress: islandContainer.timerProgress
                        timerRemainingSeconds: islandContainer.timerRemainingSeconds
                        timerRunning: islandContainer.timerRunning
                        recordingElapsedText: root.captureElapsedText
                        recordingPaused: root.captureController ? !!root.captureController.recordingPaused : false
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.liveDualLayerVisible
                        onActivityActivated: function(kind) {
                            islandContainer.suppressCapsuleClick(true);
                            islandContainer.expandActivity(kind);
                        }
                        onCycleRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            islandContainer.cycleLiveActivity();
                        }
                    }
                }
            }

            Loader {
                id: timerExpandedLoader
                anchors.fill: parent
                active: islandContainer.timerExpandedLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    TimerExpandedLayer {
                        progress: islandContainer.timerProgress
                        remainingSeconds: islandContainer.timerRemainingSeconds
                        totalSeconds: islandContainer.timerTotalSeconds
                        running: islandContainer.timerRunning
                        textFontFamily: root.textFontFamily
                        iconFontFamily: root.iconFontFamily
                        showCondition: islandContainer.timerExpandedLayerVisible
                        onControlPressed: islandContainer.suppressCapsuleClick(true)
                        onToggleRequested: islandContainer.toggleTimer(
                            islandContainer.timerSelectedHours,
                            islandContainer.timerSelectedMinutes
                        )
                        onCancelRequested: {
                            islandContainer.resetTimer();
                            islandContainer.smartRestoreState();
                        }
                    }
                }
            }

            Loader {
                id: expandedPlayerLoader
                anchors.fill: parent
                active: islandContainer.expandedLayerVisible
                asynchronous: false
                visible: active
                onLoaded: {
                    if (islandContainer.openTimerPageWhenExpanded
                            && item && item.openTimerPage) {
                        item.openTimerPage();
                        islandContainer.openTimerPageWhenExpanded = false;
                    }
                }

                sourceComponent: Component {
                    ExpandedPlayerLayer {
                        currentArtUrl: islandContainer.currentArtUrl
                        currentTrack: islandContainer.currentTrack
                        currentArtist: islandContainer.currentArtist
                        timePlayed: islandContainer.timePlayed
                        timeTotal: islandContainer.timeTotal
                        trackProgress: islandContainer.trackProgress
                        activePlayer: islandContainer.activePlayer
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        timerSelectedHours: islandContainer.timerSelectedHours
                        timerSelectedMinutes: islandContainer.timerSelectedMinutes
                        timerTotalSeconds: islandContainer.timerTotalSeconds
                        timerRemainingSeconds: islandContainer.timerRemainingSeconds
                        timerRunning: islandContainer.timerRunning
                        timerActive: islandContainer.timerActive
                        showCondition: islandContainer.expandedLayerVisible
                        onControlPressed: islandContainer.suppressCapsuleClick()
                        onBackgroundClicked: islandContainer.smartRestoreState()
                        onKeyboardFocusRequested: islandContainer.requestExpandedPlayerKeyboardFocus()
                        onKeyboardFocusReleased: islandContainer.releaseExpandedPlayerKeyboardFocus()
                        onPreviousRequested: mediaController.previous()
                        onTimerToggleRequested: function(hours, minutes) {
                            islandContainer.toggleTimer(hours, minutes);
                        }
                        onTimerResetRequested: islandContainer.resetTimer()
                        onTimerDurationRequested: function(hours, minutes) {
                            if (!islandContainer.timerActive)
                                islandContainer.syncTimerDuration(hours, minutes);
                        }
                    }
                }
            }

            Loader {
                id: bluetoothExpandedLoader
                anchors.fill: parent
                active: islandContainer.bluetoothExpandedLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    BluetoothExpandedLayer {
                        device: islandContainer.bluetoothExpandedDevice
                        volumeLevel: islandContainer.currentVolume
                        iconText: ""
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.bluetoothExpandedLayerVisible
                    }
                }
            }

            Loader {
                id: captureRecordingLoader
                anchors.fill: parent
                active: islandContainer.captureRecordingLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    CaptureRecordingLayer {
                        elapsedText: root.captureElapsedText
                        paused: root.captureController ? !!root.captureController.recordingPaused : false
                        onPauseToggleRequested: {
                            if (root.captureController)
                                root.captureController.togglePauseRecording();
                        }
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.timeFontFamily
                        showCondition: islandContainer.captureRecordingLayerVisible
                        onStopRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            if (root.captureController)
                                root.captureController.stopRecording();
                        }
                    }
                }
            }

            Loader {
                id: captureScreenshotLoader
                anchors.fill: parent
                active: islandContainer.captureScreenshotLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    CaptureShotLayer {
                        filePath: root.captureScreenshotPath
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.captureScreenshotLayerVisible
                        onCopyRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            if (root.captureController)
                                root.captureController.copyLastScreenshot();
                        }
                        onAnnotateRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            if (root.captureController)
                                root.captureController.annotateLastScreenshot();
                            root.dismissCaptureScreenshotWindow();
                        }
                        onOpenRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            if (root.captureController)
                                root.captureController.openLastScreenshot();
                            root.dismissCaptureScreenshotWindow();
                        }
                        onDeleteRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            if (root.captureController)
                                root.captureController.deleteLastScreenshot();
                            root.dismissCaptureScreenshotWindow();
                        }
                        onDismissRequested: root.dismissCaptureScreenshotWindow()
                    }
                }
            }

            Loader {
                id: notificationLoader
                anchors.fill: parent
                active: islandContainer.notificationLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    NotificationLayer {
                        appName: islandContainer.notificationAppName
                        summary: islandContainer.notificationSummary
                        body: islandContainer.notificationBody
                        expanded: islandContainer.notificationExpanded
                        toggleButton: userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)
                        iconText: root.notificationStatusIcon
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: true
                        onExpansionToggleRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            islandContainer.toggleNotificationExpansionIfNeeded();
                        }
                    }
                }
            }

            Loader {
                id: controlCenterLoader
                anchors.fill: parent
                active: islandContainer.controlCenterLayerVisible || root.anyConnectivityDetailMounted
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    IosControlCenterLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.controlCenterLayerVisible
                    }
                }
            }

            Loader {
                id: notificationCenterLoader
                anchors.fill: parent
                active: islandContainer.notificationCenterLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    NotificationCenterLayer {
                        notificationModel: islandContainer.notificationHistoryModel
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily

                        onClearAllRequested: {
                            islandContainer.notificationHistoryModel.clear();
                        }
                    }
                }
            }

            Loader {
                id: wallpaperPickerLoader
                anchors.fill: parent
                active: islandContainer.wallpaperPickerLayerVisible
                asynchronous: false
                visible: islandContainer.wallpaperPickerLayerVisible
                onLoaded: root.focusWallpaperPicker()

                sourceComponent: Component {
                    WallpaperPickerLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        activeWallpaper: root.wallpaperPickerActiveWallpaper
                        showCondition: islandContainer.wallpaperPickerLayerVisible
                        onWallpaperApplied: filePath => root.wallpaperPickerActiveWallpaper = filePath
                        onWallpaperApplySucceeded: filePath => root.handleWallpaperApplySucceeded(filePath)
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: applicationLauncherLoader
                anchors.fill: parent
                active: islandContainer.applicationLauncherLayerVisible
                asynchronous: false
                visible: islandContainer.applicationLauncherLayerVisible
                onLoaded: root.focusApplicationLauncher()

                sourceComponent: Component {
                    ApplicationLauncherLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.applicationLauncherLayerVisible
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: overviewLoader

                anchors.fill: parent
                active: root.overviewLoaderActive
                asynchronous: false
                visible: root.overviewContentVisible

                onStatusChanged: {
                    if (status === Loader.Ready && root.overviewPreparing) {
                        root.beginOverviewOpening();
                    }
                }

                sourceComponent: Component {
                    WorkspaceOverviewScene {
                        screen: root.screen
                        showCondition: root.overviewVisible
                        previewsEnabled: root.overviewContentVisible
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        wallpaperPath: root.overviewWallpaperSource
                        windowCornerRadius: root.overviewWindowCornerRadius
                        onCloseRequested: root.closeOverviewEverywhere()
                    }
                }
            }

        }

        Item {
            id: timerBubble

            property bool mounted: islandContainer.timerBubbleWanted
            property real reveal: islandContainer.timerBubbleWanted ? 1 : 0
            readonly property int bubbleSize: 34
            readonly property real hiddenX: mainCapsule.x + mainCapsule.width - width * 0.62
            readonly property real shownX: mainCapsule.x + mainCapsule.width + 8
            readonly property real centerY: mainCapsule.y + mainCapsule.height / 2 - height / 2

            width: bubbleSize
            height: bubbleSize
            x: hiddenX + (shownX - hiddenX) * reveal
            y: centerY + (1 - reveal) * 10
            z: 6
            visible: mounted
            opacity: reveal * root.autoHideProgress
            scale: (0.55 + reveal * 0.45) * (0.96 + root.autoHideProgress * 0.04) * (1 + islandContainer.timerCompletionPulse * 0.12)
            transformOrigin: Item.Center

            Connections {
                target: islandContainer

                function onTimerBubbleWantedChanged() {
                    timerBubbleShowAnimation.stop();
                    timerBubbleHideAnimation.stop();

                    if (islandContainer.timerBubbleWanted) {
                        timerBubble.mounted = true;
                        timerBubbleShowAnimation.restart();
                    } else {
                        timerBubbleHideAnimation.restart();
                    }
                }

                function onTimerProgressChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerRemainingSecondsChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerTotalSecondsChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerCompletionAnimatingChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerCompletionFlashChanged() {
                    timerBubbleRing.requestPaint();
                }
            }

            NumberAnimation {
                id: timerBubbleShowAnimation

                target: timerBubble
                property: "reveal"
                from: timerBubble.reveal
                to: 1
                duration: 360
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: timerBubbleHideAnimation

                target: timerBubble
                property: "reveal"
                from: timerBubble.reveal
                to: 0
                duration: 280
                easing.type: Easing.InCubic
                onStopped: {
                    if (!islandContainer.timerBubbleWanted && timerBubble.reveal <= 0.001)
                        timerBubble.mounted = false;
                }
            }

            SequentialAnimation {
                id: timerBubbleCompletionAnimation

                running: islandContainer.timerCompletionAnimating

                onStarted: {
                    timerBubbleShowAnimation.stop();
                    timerBubbleHideAnimation.stop();
                    timerBubble.mounted = true;
                    timerBubble.reveal = 1;
                }

                onStopped: {
                    if (islandContainer.timerCompletionAnimating)
                        islandContainer.timerCompletionAnimating = false;
                    islandContainer.timerCompletionPulse = 0;
                    islandContainer.timerCompletionFlash = 0;
                    timerBubbleRing.requestPaint();
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionPulse"
                        from: 0
                        to: 1
                        duration: 140
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionFlash"
                        from: 0
                        to: 1
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionPulse"
                        from: 1
                        to: 0
                        duration: 380
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionFlash"
                        from: 1
                        to: 0
                        duration: 380
                        easing.type: Easing.InOutQuad
                    }
                }

                PauseAnimation {
                    duration: 380
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: width / 2
                color: StyleTokens.black
            }

            Canvas {
                id: timerBubbleRing

                anchors.fill: parent
                anchors.margins: 1

                Component.onCompleted: requestPaint()
                onVisibleChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    const centerX = width / 2;
                    const centerY = height / 2;
                    const completionActive = islandContainer.timerCompletionAnimating;
                    const flash = Math.max(0, Math.min(1, islandContainer.timerCompletionFlash));
                    const lineWidth = completionActive ? 3 + flash : 3;
                    const radius = Math.min(width, height) / 2 - lineWidth / 2;
                    const progress = Math.max(0, Math.min(1, islandContainer.timerProgress));
                    const startAngle = -Math.PI / 2;
                    const endAngle = startAngle - Math.PI * 2 * progress;

                    ctx.clearRect(0, 0, width, height);
                    ctx.lineCap = "round";
                    ctx.lineWidth = lineWidth;

                    ctx.beginPath();
                    ctx.strokeStyle = "#303036";
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                    ctx.stroke();

                    if (completionActive) {
                        if (flash > 0) {
                            ctx.beginPath();
                            ctx.lineWidth = lineWidth + 1.5;
                            ctx.strokeStyle = "rgba(255, 204, 0, " + (0.18 * flash) + ")";
                            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                            ctx.stroke();
                        }

                        ctx.beginPath();
                        ctx.lineWidth = lineWidth;
                        ctx.strokeStyle = "rgba(255, 204, 0, " + (0.72 + 0.28 * flash) + ")";
                        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                        ctx.stroke();
                    } else if (progress > 0) {
                        ctx.beginPath();
                        ctx.strokeStyle = "#ffcc00";
                        ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -1
                text: "󰔛"
                color: "white"
                font.pixelSize: root.iconFontSize - 1
                font.family: root.iconFontFamily
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                enabled: timerBubble.mounted && root.autoHideProgress > 0.5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    if (root.autoHideEnabled) {
                        root.autoHidePointerInside = true;
                        root.showAutoHiddenIsland();
                    }
                }
                onExited: {
                    if (root.autoHideEnabled) {
                        root.autoHidePointerInside = false;
                        root.scheduleAutoHide();
                    }
                }
                onClicked: islandContainer.showExpandedTimerPage()
            }
        }

        ConnectivityDetailShell {
            id: wifiConnectivityDetailShell

            open: root.wifiConnectivityDetailOpen
            mounted: root.wifiConnectivityDetailMounted
            rightSide: false
            panelKind: "wifi"
            provider: controlCenterLoader.item
            mainCapsule: mainCapsule
            availableWidth: root.width
            detailWidth: root.connectivityDetailWidth
            detailHeight: root.connectivityDetailHeight
            detailGap: root.connectivityDetailGap
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            heroFontFamily: root.heroFontFamily
        }

        ConnectivityDetailShell {
            id: bluetoothConnectivityDetailShell

            open: root.bluetoothConnectivityDetailOpen
            mounted: root.bluetoothConnectivityDetailMounted
            rightSide: true
            panelKind: "bluetooth"
            provider: controlCenterLoader.item
            mainCapsule: mainCapsule
            availableWidth: root.width
            detailWidth: root.connectivityDetailWidth
            detailHeight: root.connectivityDetailHeight
            detailGap: root.connectivityDetailGap
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            heroFontFamily: root.heroFontFamily
        }
    }

    MouseArea {
        id: autoHideRevealArea

        x: root.autoHideRevealX
        y: 0
        z: 20
        width: root.autoHideRevealWidth
        height: root.autoHideRevealHeight
        enabled: root.autoHideEnabled
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            root.autoHidePointerInside = true;
            root.showAutoHiddenIsland("edge");
        }

        onExited: {
            root.autoHidePointerInside = false;
            root.scheduleAutoHide();
        }
    }

    IslandRootGestureArea {
        anchors.fill: parent
        enabled: root.topGestureInputActive
        islandController: islandContainer
        capsule: mainCapsule
    }
}
