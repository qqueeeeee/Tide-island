pragma ComponentBehavior: Bound

import QtQuick

// Reference `NotifyBanner`: 372 x 58 momentary banner for a single arrival —
// 36px app tile, bold title, dim body, app name on the right.
Item {
    id: root

    property var item: null
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
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        Rectangle {
            id: tile

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 10
            color: tokens.chip

            Text {
                anchors.centerIn: parent
                text: root.item ? String(root.item.glyph) : tokens.glyphBell
                color: root.item ? root.item.tint : tokens.accent
                font.family: root.iconFontFamily
                font.pixelSize: 16
            }
        }

        Text {
            id: appName

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.item ? String(root.item.app) : ""
            color: tokens.fg40
            font.family: root.textFontFamily
            font.pixelSize: 10
        }

        Column {
            anchors.left: tile.right
            anchors.leftMargin: 12
            anchors.right: appName.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.item ? String(root.item.title) : ""
                color: tokens.fg
                elide: Text.ElideRight
                font.family: root.textFontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: root.item ? String(root.item.body) : ""
                color: tokens.fg60
                elide: Text.ElideRight
                font.family: root.textFontFamily
                font.pixelSize: 11
            }
        }
    }
}
