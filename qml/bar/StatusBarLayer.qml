pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend
import "." as Bar

// Fully transparent iOS-style status bar. It is hosted by its own layer-shell
// surface (qml/nucleus/NucleusStatusBarWindow.qml) with its own height, so
// island geometry changes can never move bar content.
//
// Everything visual here is driven by UserConfig keys (statusBar*) so the bar is
// as configurable as the island: height, baseline, typography, colours, per-item
// toggles, workspace dot metrics and an optional background plate.
Item {
    id: root

    readonly property var userConfig: UserConfig

    // Geometry of the island capsule, supplied by the host window.
    property real capsuleX: 0
    property real capsuleWidth: 0
    property real capsuleY: 0
    property real capsuleHeight: 0
    property real capsuleRestingWidth: 0
    property real capsuleRestingHeight: 0

    // Island lifecycle signals.
    property real revealProgress: 1
    property bool islandBusy: false

    property int currentWorkspace: 1
    property var workspaceIds: []
    property string timeText: ""
    property string dateText: ""
    property int batteryCapacity: -1
    property bool isCharging: false
    property bool isMuted: false
    property bool recordingActive: false
    property string recordingElapsedText: ""

    property string textFontFamily: userConfig.textFontFamily
    property string timeFontFamily: userConfig.timeFontFamily
    property string iconFontFamily: userConfig.iconFontFamily

    property bool workspacesEnabled: userConfig.statusBarShowWorkspaces
    property bool workspacesInteractive: true
    property bool activeWindowEnabled: userConfig.statusBarShowActiveWindow
    property bool statusIconsEnabled: userConfig.statusBarShowStatusIcons
    property bool clockEnabled: userConfig.statusBarShowClock

    signal workspaceFocusRequested(int workspaceId)
    signal statusClusterActivated()

    // --- Spacing -----------------------------------------------------------
    readonly property real sideMargin: userConfig.statusBarSideMargin
    // Gap between the island capsule and the nearest bar item.
    readonly property real contentGap: userConfig.statusBarIslandGap
    // Spacing between items inside each cluster.
    readonly property real itemSpacing: userConfig.statusBarItemSpacing
    readonly property real iconSpacing: userConfig.statusBarIconSpacing

    // --- Height / baseline -------------------------------------------------
    // `statusBarHeight` is the real bar height. 0 keeps the legacy behaviour of
    // following the island's resting capsule.
    readonly property real configuredHeight: userConfig.statusBarHeight
    readonly property bool followIsland: userConfig.statusBarUseIslandBaseline || configuredHeight <= 0
    readonly property real restingHeight: capsuleRestingHeight > 0 ? capsuleRestingHeight : 34
    readonly property real barHeight: configuredHeight > 0 ? configuredHeight : restingHeight
    readonly property real baselineY: followIsland
        ? capsuleY + restingHeight / 2 + userConfig.statusBarBaselineOffset
        : userConfig.statusBarTopMargin + barHeight / 2 + userConfig.statusBarBaselineOffset

    // --- Typography / colour ----------------------------------------------
    readonly property int textPixelSize: Math.max(6, userConfig.statusBarFontSize)
    readonly property int clockPixelSize: Math.max(6, userConfig.statusBarClockFontSize)
    readonly property int iconPixelSize: Math.max(6, userConfig.statusBarIconSize)
    readonly property int textWeight: Math.max(100, Math.min(900, userConfig.statusBarFontWeight))
    readonly property color textColor: userConfig.statusBarTextColor
    readonly property real textAlpha: Math.max(0.1, Math.min(1, userConfig.statusBarTextOpacity / 100))
    readonly property bool textShadow: userConfig.statusBarTextShadow

    readonly property real barOpacity: Math.max(0, Math.min(1, userConfig.statusBarOpacity / 100))
    // macOS behaviour: bar content never disappears when the island grows, it
    // just dims by a configurable amount so the island reads as focused.
    readonly property real islandDimProgress: userConfig.statusBarFadeWithIsland && islandBusy
        ? Math.max(0, Math.min(0.95, userConfig.statusBarDimAmount / 100))
        : 0

    readonly property real capsuleLeft: capsuleX
    readonly property real capsuleRight: capsuleX + capsuleWidth

    // Available room between the screen edge and the capsule, per side.
    readonly property real leftAvailable: Math.max(0, capsuleLeft - sideMargin - contentGap)
    readonly property real rightAvailable: Math.max(0, root.width - capsuleRight - sideMargin - contentGap)
    // Only when a side is physically squeezed shut do we retreat that cluster.
    readonly property real minimumClusterRoom: 36
    readonly property real slideDistance: 6

    // Input hitboxes exported to the window's layer-shell input mask.
    readonly property bool leftInputActive: visible && leftCluster.opacity > 0.3
    readonly property real leftInputX: leftCluster.x
    readonly property real leftInputY: leftCluster.y
    readonly property real leftInputWidth: leftInputActive ? leftCluster.width : 0
    readonly property real leftInputHeight: leftInputActive ? Math.max(leftCluster.height, 18) : 0

    readonly property bool rightInputActive: visible && rightCluster.opacity > 0.3
    readonly property real rightInputX: rightCluster.x
    readonly property real rightInputY: rightCluster.y
    readonly property real rightInputWidth: rightInputActive ? rightCluster.width : 0
    readonly property real rightInputHeight: rightInputActive ? Math.max(rightCluster.height, 18) : 0

    readonly property real tallestCluster: Math.max(leftCluster.height, rightCluster.height)
    readonly property real contentBottom: baselineY + tallestCluster / 2
    readonly property real requiredWindowHeight: followIsland
        ? Math.ceil(baselineY + tallestCluster / 2 + 8)
        : Math.ceil(Math.max(userConfig.statusBarTopMargin + barHeight,
                             baselineY + tallestCluster / 2 + 2))

    anchors.fill: parent
    visible: userConfig.statusBarEnabled && opacity > 0.01
    opacity: barOpacity * revealProgress
    z: 4

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // --- Optional background plate (off by default: the bar is transparent) ---
    Rectangle {
        id: plate

        visible: root.userConfig.statusBarBackgroundEnabled
        x: root.userConfig.statusBarBackgroundMargin
        width: Math.max(0, root.width - root.userConfig.statusBarBackgroundMargin * 2)
        y: root.followIsland
            ? Math.max(0, root.baselineY - root.barHeight / 2)
            : root.userConfig.statusBarTopMargin
        height: root.barHeight
        radius: root.userConfig.statusBarBackgroundRadius
        color: root.userConfig.statusBarBackgroundColor
        opacity: Math.max(0, Math.min(1, root.userConfig.statusBarBackgroundOpacity / 100))
        z: -1
    }

    // --- Left cluster: workspace dots + focused window ---
    Row {
        id: leftCluster

        readonly property bool squeezed: root.leftAvailable < root.minimumClusterRoom
        readonly property real hideProgress: squeezed ? 1 : root.islandDimProgress

        x: root.sideMargin - hideProgress * root.slideDistance
        y: root.baselineY - height / 2
        spacing: root.itemSpacing
        opacity: (1 - hideProgress) * root.textAlpha

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
        }
        Behavior on x {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        Bar.BarWorkspaceDots {
            visible: root.workspacesEnabled
            anchors.verticalCenter: parent.verticalCenter
            workspaceIds: root.workspaceIds
            currentWorkspace: root.currentWorkspace
            dotSize: root.userConfig.statusBarWorkspaceDotSize
            activeDotWidth: Math.max(root.userConfig.statusBarWorkspaceDotSize,
                                     root.userConfig.statusBarWorkspaceActiveWidth)
            spacing: root.userConfig.statusBarWorkspaceSpacing
            minimumCount: root.userConfig.statusBarWorkspaceMinimumCount
            dotColor: root.textColor
            shadowEnabled: root.textShadow
            interactive: root.workspacesInteractive && leftCluster.opacity > 0.3
            onFocusRequested: function(workspaceId) { root.workspaceFocusRequested(workspaceId); }
        }

        Bar.BarActiveWindow {
            visible: root.activeWindowEnabled
            anchors.verticalCenter: parent.verticalCenter
            textFontFamily: root.textFontFamily
            pixelSize: root.textPixelSize
            weight: root.textWeight
            textColor: root.textColor
            shadowEnabled: root.textShadow
            opacityScale: Math.max(0.2, Math.min(1, root.userConfig.statusBarActiveWindowOpacity / 100))
            maximumWidth: root.userConfig.statusBarActiveWindowMaxWidth > 0
                ? root.userConfig.statusBarActiveWindowMaxWidth
                : Math.max(0, root.leftAvailable - (root.workspacesEnabled ? 70 : 0))
        }
    }

    // --- Right cluster: status icons + clock ---
    Row {
        id: rightCluster

        readonly property bool squeezed: root.rightAvailable < root.minimumClusterRoom
        readonly property real hideProgress: squeezed ? 1 : root.islandDimProgress

        x: root.width - root.sideMargin - width + hideProgress * root.slideDistance
        y: root.baselineY - height / 2
        spacing: root.itemSpacing
        opacity: (1 - hideProgress) * root.textAlpha

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
        }
        Behavior on x {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        Bar.BarStatusCluster {
            id: statusCluster

            visible: root.statusIconsEnabled
            anchors.verticalCenter: parent.verticalCenter
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            iconPixelSize: root.iconPixelSize
            itemSpacing: root.iconSpacing
            textColor: root.textColor
            shadowEnabled: root.textShadow
            batteryScale: Math.max(0.5, root.userConfig.statusBarBatteryScale / 100)
            showWifi: root.userConfig.statusBarShowWifi
            showBluetooth: root.userConfig.statusBarShowBluetooth
            showBattery: root.userConfig.statusBarShowBattery
            showMute: root.userConfig.statusBarShowMute
            batteryCapacity: root.batteryCapacity
            isCharging: root.isCharging
            isMuted: root.isMuted
            onActivated: {
                if (rightCluster.opacity > 0.3)
                    root.statusClusterActivated();
            }
        }

        Bar.BarLabel {
            id: clockLabel

            visible: root.clockEnabled
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (root.userConfig.statusBarShowDate)
                    return root.dateText + "  " + root.timeText;
                return clockHover.hovered ? root.dateText : root.timeText;
            }
            fontFamily: root.timeFontFamily
            pixelSize: root.clockPixelSize
            weight: Math.min(900, root.textWeight + 100)
            textColor: root.textColor
            shadowEnabled: root.textShadow

            HoverHandler {
                id: clockHover
                enabled: root.userConfig.statusBarShowDateOnHover
                    && !root.userConfig.statusBarShowDate
                    && rightCluster.opacity > 0.3
            }
        }
    }
}
