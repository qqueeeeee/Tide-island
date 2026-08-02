pragma ComponentBehavior: Bound

import QtQuick

// Reference `MediaCompact`: 244 x 38, 12px side padding, 22px artwork, marquee
// title, green audio glyph on the right.
Item {
    id: root

    property string title: ""
    property string artUrl: ""
    property bool playing: true
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        AlbumArt {
            id: art

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            source: root.artUrl
        }

        Text {
            anchors.left: art.right
            anchors.leftMargin: 10
            anchors.right: wave.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: tokens.fg
            elide: Text.ElideRight
            font.family: root.textFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Text {
            id: wave

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: tokens.glyphWave
            color: tokens.accent2
            opacity: root.playing ? 1 : 0.45
            font.family: root.iconFontFamily
            font.pixelSize: 15

            SequentialAnimation on opacity {
                running: root.playing
                loops: Animation.Infinite
                NumberAnimation { to: 0.55; duration: 780; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 780; easing.type: Easing.InOutSine }
            }
        }
    }
}
