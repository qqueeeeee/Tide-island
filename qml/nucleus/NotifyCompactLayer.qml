pragma ComponentBehavior: Bound

import QtQuick

// Reference `NotifyCompact`: 246 x 38 — bell glyph, label, and either a red count
// badge or an "all clear" / "silenced" hint.
Item {
    id: root

    property int count: 0
    property bool dnd: false
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
            text: root.dnd ? tokens.glyphBellOff : tokens.glyphBell
            color: root.dnd ? tokens.fg50 : tokens.accent
            font.family: root.iconFontFamily
            font.pixelSize: 13
        }

        Rectangle {
            id: badge

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.count > 0 && !root.dnd
            width: 18
            height: 18
            radius: 9
            color: tokens.danger

            Text {
                anchors.centerIn: parent
                text: root.count > 9 ? "9+" : String(root.count)
                color: tokens.fg
                font.family: root.textFontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Text {
            id: hint

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !badge.visible
            text: root.dnd ? "silenced" : "all clear"
            color: tokens.fg40
            font.family: root.textFontFamily
            font.pixelSize: 11
        }

        Text {
            anchors.left: glyph.right
            anchors.leftMargin: 10
            anchors.right: badge.visible ? badge.left : hint.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.dnd ? "Do Not Disturb" : "Notifications"
            color: tokens.fg
            elide: Text.ElideRight
            font.family: root.textFontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }
}
