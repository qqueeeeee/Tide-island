pragma ComponentBehavior: Bound

import QtQuick

// Wallpaper picker, compact: 262 x 38 — image glyph, label, library count.
Item {
    id: root

    property WallpaperSource source: null
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
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        Text {
            id: glyph

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: tokens.glyphImage
            color: tokens.accent
            font.family: root.iconFontFamily
            font.pixelSize: 13
        }

        Text {
            anchors.left: glyph.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "Wallpaper"
            color: tokens.fg
            font.family: root.textFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: (root.source ? root.source.count : 0) + " images"
            color: tokens.fg45
            font.family: root.textFontFamily
            font.pixelSize: 11
        }
    }
}
