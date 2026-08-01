pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend
import "." as Bar

// Fully transparent iOS-style status bar. It lives inside the island's own
// PanelWindow so both surfaces share one layer-shell surface, one input mask and
// one animation clock. Content sits on the island's baseline and yields space to
// the capsule whenever it grows.
Item {
    id: root

    readonly property var userConfig: UserConfig

    // Geometry of the island capsule, supplied by DynamicIslandWindow.
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

    readonly property real sideMargin: userConfig.statusBarSideMargin
    readonly property real contentGap: 14
    readonly property real barOpacity: Math.max(0, Math.min(1, userConfig.statusBarOpacity / 100))
    // macOS behaviour: bar content never disappears when the island grows, it just
    // dims a touch so the island reads as the focused surface.
    readonly property real islandDimProgress: userConfig.statusBarFadeWithIsland && islandBusy ? 0.4 : 0
    readonly property real capsuleLeft: capsuleX
    readonly property real capsuleRight: capsuleX + capsuleWidth

    // Available room between the screen edge and the capsule, per side.
    readonly property real leftAvailable: Math.max(0, capsuleLeft - sideMargin - contentGap)
    readonly property real rightAvailable: Math.max(0, root.width - capsuleRight - sideMargin - contentGap)
    // Only when a side is physically squeezed shut do we retreat that cluster.
    readonly property real minimumClusterRoom: 36

    // Bar content is pinned to the island's *resting* baseline so it never rides
    // down with the capsule when the island expands.
    readonly property real restingHeight: capsuleRestingHeight > 0 ? capsuleRestingHeight : capsuleHeight
    readonly property real baselineY: capsuleY + restingHeight / 2
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

    readonly property real contentBottom: baselineY + Math.max(leftCluster.height, rightCluster.height) / 2
    readonly property real requiredWindowHeight: Math.ceil(baselineY + Math.max(leftCluster.height, rightCluster.height) / 2 + 8)

    anchors.fill: parent
    visible: userConfig.statusBarEnabled && opacity > 0.01
    opacity: barOpacity * revealProgress
    z: 4

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // --- Left cluster: workspace dots + focused window ---
    Row {
        id: leftCluster

        readonly property bool squeezed: root.leftAvailable < root.minimumClusterRoom
        readonly property real hideProgress: squeezed ? 1 : root.islandDimProgress

        x: root.sideMargin - hideProgress * root.slideDistance
        y: root.baselineY - height / 2
        spacing: root.contentGap
        opacity: 1 - hideProgress

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
            interactive: root.workspacesInteractive && leftCluster.opacity > 0.3
            onFocusRequested: function(workspaceId) { root.workspaceFocusRequested(workspaceId); }
        }

        Bar.BarActiveWindow {
            visible: root.activeWindowEnabled
            anchors.verticalCenter: parent.verticalCenter
            textFontFamily: root.textFontFamily
            pixelSize: Math.max(11, root.userConfig.bodyFontSize - 3)
            maximumWidth: Math.max(0, root.leftAvailable - (root.workspacesEnabled ? 70 : 0))
        }
    }

    // --- Right cluster: status icons + clock ---
    Row {
        id: rightCluster

        readonly property bool squeezed: root.rightAvailable < root.minimumClusterRoom
        readonly property real hideProgress: squeezed ? 1 : root.islandDimProgress

        x: root.width - root.sideMargin - width + hideProgress * root.slideDistance
        y: root.baselineY - height / 2
        spacing: root.contentGap
        opacity: 1 - hideProgress

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
            iconPixelSize: Math.max(11, root.userConfig.iconFontSize - 5)
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
            text: clockHover.hovered ? root.dateText : root.timeText
            fontFamily: root.timeFontFamily
            pixelSize: Math.max(11, root.userConfig.bodyFontSize - 2)
            weight: Font.Bold

            HoverHandler {
                id: clockHover
                enabled: root.userConfig.statusBarShowDateOnHover && rightCluster.opacity > 0.3
            }
        }
    }
}
