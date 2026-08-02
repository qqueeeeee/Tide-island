import QtQuick
import TideIsland 1.0

// Live miniature of the top strip: wallpaper-ish backdrop, the island capsule
// at the configured margin/scale/radius, bar items at the configured gaps and
// the reserved window gap drawn underneath.
Rectangle {
    id: root

    readonly property real islandScale: ConfigStore.number("islandScale") / 100
    readonly property real capsuleWidth: 148 * islandScale
    readonly property real capsuleHeight: 34 * islandScale
    readonly property real topMargin: ConfigStore.number("islandTopMargin")
    readonly property real bottomGap: ConfigStore.number("islandBottomGap")
    readonly property real sideMargin: ConfigStore.number("statusBarSideMargin")
    readonly property real islandGap: ConfigStore.number("statusBarIslandGap")
    readonly property real itemSpacing: ConfigStore.number("statusBarItemSpacing")
    readonly property real baselineOffset: ConfigStore.number("statusBarBaselineOffset")
    readonly property real baselineY: topMargin + capsuleHeight / 2 + baselineOffset

    implicitHeight: 176
    radius: AppTheme.radiusCard
    color: AppTheme.previewBg
    border.width: 1
    border.color: AppTheme.cardBorder
    clip: true

    // Wallpaper glow so the black capsule reads as floating.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#3a2a63" }
            GradientStop { position: 0.55; color: "#1b1b2c" }
            GradientStop { position: 1.0; color: "#101018" }
        }
        opacity: 0.9
    }

    // Reserved strip: where app windows start.
    Rectangle {
        x: 10
        width: parent.width - 20
        y: ConfigStore.flag("islandReserveSpace")
            ? root.topMargin + root.capsuleHeight + root.bottomGap
            : root.topMargin
        height: parent.height - y - 10
        radius: 10
        color: "#ffffff"
        opacity: 0.14

        Text {
            anchors.centerIn: parent
            text: "app window"
            color: "#ffffff"
            opacity: 0.7
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
        }
    }

    // Left bar cluster.
    Row {
        x: root.sideMargin
        y: root.baselineY - height / 2
        spacing: root.itemSpacing
        opacity: ConfigStore.flag("statusBarEnabled") ? ConfigStore.number("statusBarOpacity") / 100 : 0

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            visible: ConfigStore.flag("statusBarShowWorkspaces")

            Repeater {
                model: 4
                delegate: Rectangle {
                    required property int index
                    width: index === 1 ? 16 : 6
                    height: 6
                    radius: 3
                    color: "#ffffff"
                    opacity: index === 1 ? 0.95 : 0.4
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: ConfigStore.flag("statusBarShowActiveWindow")
            text: "Ghostty"
            color: "#ffffff"
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
        }
    }

    // Right bar cluster.
    Row {
        x: root.width - root.sideMargin - width
        y: root.baselineY - height / 2
        spacing: root.itemSpacing
        opacity: ConfigStore.flag("statusBarEnabled") ? ConfigStore.number("statusBarOpacity") / 100 : 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: ConfigStore.flag("statusBarShowStatusIcons")
            text: "84%"
            color: "#ffffff"
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: ConfigStore.flag("statusBarShowClock")
            text: ConfigStore.text("clockFormat") === "24" ? "21:41" : "9:41"
            color: "#ffffff"
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    // The capsule itself.
    Rectangle {
        x: Math.round((root.width - width) / 2)
        y: root.topMargin
        width: root.capsuleWidth
        height: root.capsuleHeight
        radius: Math.min(height / 2, ConfigStore.number("islandCornerRadius"))
        color: "#000000"
        opacity: ConfigStore.number("islandBackgroundOpacity") / 100

        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#14ffffff" }
                GradientStop { position: 0.5; color: "#00ffffff" }
            }
        }
    }

    // Gap annotations.
    Text {
        x: 12
        y: 8
        text: "top " + root.topMargin + " px  ·  gap " + root.bottomGap + " px  ·  scale " + Math.round(root.islandScale * 100) + "%"
        color: "#ffffff"
        opacity: 0.55
        font.family: AppTheme.fontFamily
        font.pixelSize: 11
    }
}
