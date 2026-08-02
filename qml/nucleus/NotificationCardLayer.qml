pragma ComponentBehavior: Bound

import QtQuick

// Reference `NotificationExpanded` minus the action row: 348 x 106, 16px side
// padding, 36px rounded chip, title + body, draining life bar.
Item {
    id: root

    property string appName: ""
    property string summary: ""
    property string body: ""
    property real lifeProgress: 1
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
        anchors.topMargin: 14
        anchors.bottomMargin: 16

        Rectangle {
            id: chip

            anchors.left: parent.left
            anchors.top: parent.top
            width: 36
            height: 36
            radius: 9
            color: tokens.chip

            Text {
                anchors.centerIn: parent
                text: tokens.glyphBell
                color: tokens.accent
                font.family: root.iconFontFamily
                font.pixelSize: 16
            }
        }

        Column {
            anchors.left: chip.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 3

            Text {
                width: parent.width
                text: root.summary !== "" ? root.summary : root.appName
                color: tokens.fg
                elide: Text.ElideRight
                font.family: root.textFontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: root.appName
                color: tokens.fg55
                elide: Text.ElideRight
                font.family: root.textFontFamily
                font.pixelSize: 10.5
            }
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: root.body
            color: tokens.fg70
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            font.family: root.textFontFamily
            font.pixelSize: 11.5
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        height: 2
        radius: 1
        color: "#1affffff"
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: 1
            width: parent.width * Math.max(0, Math.min(1, root.lifeProgress))
            color: tokens.fg35
        }
    }
}
