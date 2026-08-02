pragma ComponentBehavior: Bound

import QtQuick

// Circular icon button — the QML twin of the React `IslandButton variant="circle"`.
Rectangle {
    id: root

    property string glyph: ""
    property string iconFontFamily: ""
    property real glyphSize: 18
    property bool active: false
    property color activeColor: tokens.nav
    property color inactiveColor: tokens.chip
    property color glyphColor: tokens.fg

    signal activated()

    readonly property bool hovered: hoverHandler.hovered
    readonly property bool pressedDown: mouseArea.pressed

    IslandTokens { id: tokens }
    IslandMotion { id: motion }

    implicitWidth: 42
    implicitHeight: 42
    width: implicitWidth
    height: implicitHeight
    radius: height / 2
    color: root.active
        ? root.activeColor
        : (root.pressedDown ? tokens.chipPressed : (root.hovered ? tokens.chipHover : root.inactiveColor))
    scale: root.pressedDown ? 0.94 : (root.hovered ? 1.04 : 1)

    Behavior on color { ColorAnimation { duration: motion.buttonColorDuration } }
    Behavior on scale {
        SpringAnimation {
            spring: motion.buttonSpring
            damping: motion.buttonDamping
            mass: 1.0
            epsilon: 0.005
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.glyph !== ""
        text: root.glyph
        color: root.glyphColor
        font.family: root.iconFontFamily
        font.pixelSize: root.glyphSize
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
