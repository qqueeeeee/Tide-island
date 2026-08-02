pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Device connection ("AirPods connected") expanded layout.
//
// Read-only by design: this is a transient acknowledgement, not a control card,
// so it has no buttons and no volume slider. Layout mirrors iOS: device glyph on
// the left, device name plus connection state on the right, battery percentage
// with a small battery pill on the trailing edge.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property bool showCondition: false
    property var device: null
    // Kept for source compatibility with existing call sites; unused, because
    // this layout intentionally exposes no controls.
    property real volumeLevel: -1
    property string iconText: ""
    property string iconFontFamily: ""
    property string textFontFamily: ""

    readonly property string deviceName: {
        if (!device) return "Bluetooth device";

        const preferred = String(device.deviceName === undefined || device.deviceName === null ? "" : device.deviceName).trim();
        if (preferred.length > 0) return preferred;

        const alias = String(device.name === undefined || device.name === null ? "" : device.name).trim();
        if (alias.length > 0) return alias;

        const address = String(device.address === undefined || device.address === null ? "" : device.address).trim();
        return address.length > 0 ? address : "Bluetooth device";
    }
    readonly property bool batteryAvailable: !!(device && device.batteryAvailable)
    readonly property real batteryRawValue: batteryAvailable ? Math.max(0, Number(device.battery) || 0) : -1
    readonly property int batteryPercent: batteryAvailable
        ? Math.max(0, Math.min(100, Math.round(batteryRawValue <= 1 ? batteryRawValue * 100 : batteryRawValue)))
        : -1
    readonly property color batteryColor: {
        if (!batteryAvailable) return "#5d6068";
        if (batteryPercent <= 10) return "#ff3b30";
        if (batteryPercent <= 20) return "#ffcc00";
        return "#34c759";
    }

    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    anchors.fill: parent
    anchors.leftMargin: 30
    anchors.rightMargin: 30
    anchors.topMargin: 16
    anchors.bottomMargin: 16
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    // --- Left: device glyph (earbuds drawn from primitives, so the layout does
    // not depend on an icon font shipping a headphone glyph) ----------------
    Item {
        id: deviceGlyph

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        height: 52

        Text {
            anchors.centerIn: parent
            visible: root.iconText !== ""
            text: root.iconText
            color: "#0a84ff"
            font.pixelSize: root.userConfig.iconFontSize + 14
            font.family: root.iconFontFamily
        }

        Item {
            anchors.centerIn: parent
            visible: root.iconText === ""
            width: 34
            height: 34

            Repeater {
                model: 2

                Item {
                    required property int index

                    x: index === 0 ? 2 : 20
                    y: 4
                    width: 12
                    height: 26

                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "#f5f5f7"
                    }

                    Rectangle {
                        x: 4.5
                        y: 10
                        width: 3
                        height: 16
                        radius: 1.5
                        color: "#f5f5f7"
                    }
                }
            }
        }
    }

    // --- Right: name, connected state, battery -----------------------------
    Item {
        anchors.left: deviceGlyph.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: nameText.height + stateText.height + 4

        Row {
            id: batteryPill

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryAvailable ? root.batteryPercent + "%" : "--"
                color: root.batteryAvailable ? "#ffffff" : "#8e8e93"
                font.family: root.textFontFamily
                font.pixelSize: root.userConfig.bodyFontSize
                font.weight: Font.DemiBold
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 14

                Rectangle {
                    anchors.fill: parent
                    anchors.rightMargin: 3
                    radius: 4
                    color: "transparent"
                    border.color: "#8e8e93"
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        radius: 2
                        width: root.batteryAvailable ? (parent.width - 4) * (root.batteryPercent / 100.0) : 0
                        color: root.batteryColor

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 160 }
                        }
                    }
                }

                Rectangle {
                    width: 2
                    height: 6
                    radius: 1
                    color: "#8e8e93"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Text {
            id: nameText

            anchors.left: parent.left
            anchors.right: batteryPill.left
            anchors.rightMargin: 12
            anchors.top: parent.top
            text: root.deviceName
            color: "#ffffff"
            font.family: root.textFontFamily
            font.pixelSize: root.userConfig.bodyFontSize + 1
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            id: stateText

            anchors.left: parent.left
            anchors.right: batteryPill.left
            anchors.rightMargin: 12
            anchors.top: nameText.bottom
            anchors.topMargin: 3
            text: "Connected"
            color: "#34c759"
            font.family: root.textFontFamily
            font.pixelSize: Math.max(10, root.userConfig.bodyFontSize - 3)
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }
}
