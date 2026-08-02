pragma ComponentBehavior: Bound

import QtQuick

// Reference `NotificationCompact` for a saved screenshot: 246 x 37, camera glyph
// in island yellow plus a single 12.5px line.
Item {
    id: root

    property string label: "Screenshot Saved"
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

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tokens.glyphCamera
            color: tokens.accent
            font.family: root.iconFontFamily
            font.pixelSize: 15
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: tokens.fg
            elide: Text.ElideRight
            font.family: root.textFontFamily
            font.pixelSize: 12.5
            font.weight: Font.Medium
        }
    }
}
