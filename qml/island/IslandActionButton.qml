pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Pill-shaped action button used by island activity layers (screenshot actions,
// recording controls, toast actions). Press/hover feedback is spring driven so
// it matches the capsule's own motion.
Rectangle {
    id: root

    readonly property var userConfig: UserConfig

    property string label: ""
    property string iconText: ""
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool destructive: false
    // Solid fill instead of a translucent chip (used for the stop button).
    property bool filled: false
    property bool accent: false
    property bool compact: false
    property real horizontalPadding: compact ? 14 : 22

    signal activated()

    readonly property bool hovered: hoverHandler.hovered
    readonly property bool pressedDown: buttonArea.pressed

    implicitWidth: contentRow.implicitWidth + horizontalPadding
    implicitHeight: root.compact ? 26 : 30
    width: implicitWidth
    height: implicitHeight
    radius: height / 2

    color: {
        if (root.destructive)
            return root.filled
                ? (root.pressedDown ? "#e03c32" : (root.hovered ? "#ff5f55" : "#ff453a"))
                : (root.pressedDown ? "#66ff453a" : (root.hovered ? "#4dff453a" : "#33ff453a"));
        if (root.accent)
            return root.pressedDown ? "#ffffff" : (root.hovered ? "#e6ffffff" : "#ccffffff");
        return root.pressedDown ? "#3dffffff" : (root.hovered ? "#2effffff" : "#1fffffff");
    }
    scale: root.pressedDown ? 0.94 : 1

    IslandMotion { id: motion }

    Behavior on color {
        ColorAnimation { duration: motion.buttonColorDuration }
    }

    Behavior on scale {
        SpringAnimation {
            spring: motion.buttonSpring
            damping: motion.buttonDamping
            mass: 1.0
            epsilon: 0.005
        }
    }

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: root.iconText !== "" && root.label !== "" ? 6 : 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.iconText !== ""
            text: root.iconText
            color: root.accent ? "#000000" : (root.destructive && !root.filled ? "#ff8a80" : "#ffffff")
            font.family: root.iconFontFamily
            font.pixelSize: Math.max(11, root.userConfig.bodyFontSize - 1)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.accent ? "#000000" : (root.destructive && !root.filled ? "#ff8a80" : "#ffffff")
            font.family: root.textFontFamily
            font.pixelSize: Math.max(11, root.userConfig.bodyFontSize - 2)
            font.weight: Font.DemiBold
        }
    }

    HoverHandler { id: hoverHandler }

    MouseArea {
        id: buttonArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
