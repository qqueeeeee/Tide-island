pragma ComponentBehavior: Bound

import QtQuick

// Capsule slider — QML twin of the React control-centre `Slider`:
// 26px tall pill, 85% white fill, glyph on the left (flipping to black once the
// fill passes under it) and the percentage pinned right.
Item {
    id: root

    property real value: 0
    property string glyph: ""
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property bool interactive: true

    signal moved(real value)
    signal released(real value)

    IslandTokens { id: tokens }

    implicitHeight: 26
    height: implicitHeight

    Rectangle {
        id: track

        anchors.fill: parent
        radius: height / 2
        color: tokens.chip
        clip: true

        Rectangle {
            id: fill

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: height / 2
            width: Math.max(0, Math.min(1, root.value)) * track.width
            color: tokens.fg85

            Behavior on width {
                SpringAnimation { spring: 4.2; damping: 0.62; mass: 1.0; epsilon: 0.25 }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            font.family: root.iconFontFamily
            font.pixelSize: 14
            color: root.value > 0.12 ? tokens.onFill : tokens.fg70
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
            font.family: root.textFontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: tokens.fg60
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function valueAt(mouseX) {
            return Math.max(0, Math.min(1, mouseX / Math.max(1, width)));
        }

        onPressed: (mouse) => root.moved(valueAt(mouse.x))
        onPositionChanged: (mouse) => { if (pressed) root.moved(valueAt(mouse.x)); }
        onReleased: (mouse) => root.released(valueAt(mouse.x))
    }
}
