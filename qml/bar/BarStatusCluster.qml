pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import IslandBackend

// Right-hand status cluster: wifi, bluetooth, mute, battery. All data comes from
// the island's existing backends (WifiController / SysBackend via the window).
Item {
    id: root

    readonly property var wifiController: WifiController

    property string iconFontFamily: ""
    property string textFontFamily: ""
    property int iconPixelSize: 13
    property int batteryCapacity: -1
    property bool isCharging: false
    property bool isMuted: false
    property bool showWifi: true
    property bool showBluetooth: true
    property bool showMute: true
    property bool showBattery: true
    property real itemSpacing: 9
    property color textColor: "white"
    property bool shadowEnabled: true
    property real batteryScale: 1

    signal activated()

    readonly property string wifiGlyph: "\uf1eb"
    readonly property string bluetoothGlyph: "\uf294"
    readonly property string muteGlyph: "\u{F075F}"

    readonly property bool wifiSupported: wifiController ? wifiController.supported : false
    readonly property bool wifiEnabled: wifiController ? wifiController.enabled : false
    readonly property bool wifiConnected: wifiController
        && wifiController.enabled
        && String(wifiController.currentSsid || "") !== ""

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var bluetoothDeviceValues: bluetoothAdapter ? bluetoothAdapter.devices.values : []
    readonly property bool bluetoothEnabled: bluetoothAdapter ? !!bluetoothAdapter.enabled : false
    readonly property bool bluetoothConnected: {
        const devices = bluetoothDeviceValues || [];
        for (let index = 0; index < devices.length; index++) {
            if (devices[index] && devices[index].connected)
                return true;
        }
        return false;
    }

    implicitWidth: clusterRow.implicitWidth
    implicitHeight: Math.max(18, clusterRow.implicitHeight)
    width: implicitWidth
    height: implicitHeight

    Row {
        id: clusterRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: root.itemSpacing

        BarLabel {
            visible: root.showMute && root.isMuted
            anchors.verticalCenter: parent.verticalCenter
            text: root.muteGlyph
            fontFamily: root.iconFontFamily
            pixelSize: root.iconPixelSize
            textColor: root.textColor
            shadowEnabled: root.shadowEnabled
            weight: Font.Normal
        }

        BarLabel {
            visible: root.showBluetooth && root.bluetoothEnabled
            anchors.verticalCenter: parent.verticalCenter
            text: root.bluetoothGlyph
            fontFamily: root.iconFontFamily
            pixelSize: root.iconPixelSize
            textColor: root.textColor
            shadowEnabled: root.shadowEnabled
            weight: Font.Normal
            opacity: root.bluetoothConnected ? 1 : 0.45
        }

        BarLabel {
            visible: root.showWifi && root.wifiSupported
            anchors.verticalCenter: parent.verticalCenter
            text: root.wifiGlyph
            fontFamily: root.iconFontFamily
            pixelSize: root.iconPixelSize
            textColor: root.textColor
            shadowEnabled: root.shadowEnabled
            weight: Font.Normal
            opacity: root.wifiConnected ? 1 : (root.wifiEnabled ? 0.55 : 0.3)
        }

        BarBatteryIndicator {
            visible: root.showBattery && root.batteryCapacity >= 0
            anchors.verticalCenter: parent.verticalCenter
            level: root.batteryCapacity
            charging: root.isCharging
            textFontFamily: root.textFontFamily
            iconFontFamily: root.iconFontFamily
            batteryWidth: Math.round(32 * root.batteryScale)
            batteryHeight: Math.round(15 * root.batteryScale)
            tipWidth: Math.max(1, Math.round(2 * root.batteryScale))
            tipHeight: Math.max(2, Math.round(5 * root.batteryScale))
            outerRadius: Math.max(2, Math.round(5 * root.batteryScale))
            labelFontSize: Math.max(6, Math.round(11 * root.batteryScale))
            labelFontSizeCharging: Math.max(6, Math.round(10 * root.batteryScale))
            boltSize: Math.max(5, Math.round(9 * root.batteryScale))
            fillColor: root.textColor
        }
    }

    TapHandler {
        onTapped: root.activated()
    }
}
