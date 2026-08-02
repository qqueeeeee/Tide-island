pragma ComponentBehavior: Bound

import QtQuick

// Small labelled action pill — QML twin of the React `IslandButton variant="pill"`.
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property bool destructive: false

    signal activated()

    readonly property bool hovered: hoverHandler.hovered
    readonly property bool pressedDown: mouseArea.pressed

    IslandTokens { id: tokens }
    IslandMotion { id: motion }

    implicitHeight: 28
    height: implicitHeight
    radius: height / 2
    color: root.pressedDown ? tokens.chipPressed : (root.hovered ? tokens.chipHover : tokens.chip)
    scale: root.pressedDown ? 0.95 : 1

    Behavior on color { ColorAnimation { duration: motion.buttonColorDuration } }
    Behavior on scale {
        SpringAnimation {
            spring: motion.buttonSpring
            damping: motion.buttonDamping
            mass: 1.0
            epsilon: 0.005
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.glyph !== ""
            text: root.glyph
            color: root.destructive ? tokens.danger : tokens.fg85
            font.family: root.iconFontFamily
            font.pixelSize: 12
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.destructive ? tokens.danger : tokens.fg85
            font.family: root.textFontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }

    HoverHandler { id: hoverHandler }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
