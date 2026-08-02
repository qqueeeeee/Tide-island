pragma ComponentBehavior: Bound

import QtQuick

// Reference `ClipboardCompact`: 252 x 38, green clipboard glyph, "Clipboard",
// trailing "<n> items" chip.
Item {
    id: root

    property int count: 0
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
            text: tokens.glyphClipboard
            color: tokens.accent2
            font.family: root.iconFontFamily
            font.pixelSize: 13
        }

        Rectangle {
            id: chip

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: chipLabel.implicitWidth + 12
            height: 16
            radius: 5
            color: tokens.fg09

            Text {
                id: chipLabel

                anchors.centerIn: parent
                text: root.count + " items"
                color: tokens.fg50
                font.family: root.textFontFamily
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }

        Text {
            anchors.left: glyph.right
            anchors.leftMargin: 10
            anchors.right: chip.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "Clipboard"
            color: tokens.fg
            elide: Text.ElideRight
            font.family: root.textFontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }
}
