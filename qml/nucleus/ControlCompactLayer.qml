pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Reference `ControlCompact`: 246 x 38, 14px side padding, Wi-Fi glyph (blue
// when on), network name, and a 5px trailing dot at 30% white.
Item {
    id: root

    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    readonly property var wifiController: WifiController
    readonly property bool wifiEnabled: wifiController ? wifiController.enabled : false
    readonly property string wifiSsid: wifiController && wifiController.currentSsid !== ""
        ? wifiController.currentSsid
        : "Wi-Fi"

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
            text: tokens.glyphWifi
            color: root.wifiEnabled ? tokens.nav : tokens.fg35
            font.family: root.iconFontFamily
            font.pixelSize: 15
        }

        Text {
            anchors.left: glyph.right
            anchors.leftMargin: 10
            anchors.right: trailing.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.wifiEnabled ? root.wifiSsid : "Wi-Fi Off"
            color: tokens.fg
            elide: Text.ElideRight
            font.family: root.textFontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Rectangle {
            id: trailing

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: 5
            radius: 2.5
            color: "#4dffffff"
        }
    }
}
