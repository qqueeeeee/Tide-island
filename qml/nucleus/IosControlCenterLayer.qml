pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import Quickshell.Io
import IslandBackend

// iOS-style Control Centre, ported pixel-for-pixel from the React reference
// (`ControlCenterExpanded`): a row of four 42px circular toggles with 9.5px
// labels, then volume and brightness capsule sliders.
//
// 372 x 178 reference px, 16px side padding, 14px top/bottom padding.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    // Extra height above the base expanded pill; kept for API parity with the
    // previous control-centre surface.
    readonly property real controlCenterExtraHeight: 0
    readonly property real controlCenterMaximumExtraHeight: 0
    readonly property bool hasConnectivityPrompt: false

    function closeConnectivityPanels() {}

    // --- Live state --------------------------------------------------------
    readonly property var wifiController: WifiController
    readonly property bool wifiEnabled: wifiController ? wifiController.enabled : false
    readonly property string wifiSsid: wifiController && wifiController.currentSsid !== ""
        ? wifiController.currentSsid
        : "Wi-Fi"

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: bluetoothAdapter ? bluetoothAdapter.enabled : false

    property bool micMuted: false
    property bool nightLightEnabled: false

    property real volumeValue: 0
    property real brightnessValue: 0

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Component.onCompleted: {
        SystemServices.requestVolume();
        SystemServices.requestBrightness();
        micStateProcess.running = true;
    }

    Connections {
        target: SystemServices

        function onVolumeSnapshotReady(value, muted, errorString) {
            if (value >= 0) root.volumeValue = Math.max(0, Math.min(1, value));
        }

        function onBrightnessSnapshotReady(value, errorString) {
            if (value >= 0) root.brightnessValue = Math.max(0, Math.min(1, value));
        }
    }

    // Coalesce drags so we do not spawn a setter per mouse move.
    Timer {
        id: volumeApply

        interval: 60
        onTriggered: SystemServices.setVolume(root.volumeValue)
    }

    Timer {
        id: brightnessApply

        interval: 60
        onTriggered: SystemServices.setBrightness(root.brightnessValue)
    }

    Process {
        id: micStateProcess

        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED && echo muted || echo live"]
        stdout: StdioCollector {
            onStreamFinished: root.micMuted = String(text).indexOf("muted") >= 0
        }
    }

    Process {
        id: micToggleProcess

        command: ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"]
        onExited: micStateProcess.running = true
    }

    Process {
        id: nightLightProcess

        property bool enable: false
        command: ["sh", "-c", nightLightProcess.enable
            ? "pgrep -x hyprsunset >/dev/null 2>&1 || (setsid hyprsunset >/dev/null 2>&1 & sleep 0.4); hyprctl hyprsunset temperature 4500 >/dev/null 2>&1"
            : "hyprctl hyprsunset identity >/dev/null 2>&1 || pkill -x hyprsunset"]
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        anchors.bottomMargin: 14

        // --- Toggle row ----------------------------------------------------
        Row {
            id: toggleRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 8

            readonly property real cellWidth: (width - spacing * 3) / 4

            Repeater {
                model: [
                    {
                        key: "wifi",
                        glyph: tokens.glyphWifi,
                        label: root.wifiEnabled ? root.wifiSsid : "Wi-Fi",
                        active: root.wifiEnabled
                    },
                    {
                        key: "bluetooth",
                        glyph: tokens.glyphBluetooth,
                        label: "Bluetooth",
                        active: root.bluetoothEnabled
                    },
                    {
                        key: "mic",
                        glyph: root.micMuted ? tokens.glyphMicOff : tokens.glyphMic,
                        label: root.micMuted ? "Mic Muted" : "Mic",
                        active: root.micMuted
                    },
                    {
                        key: "night",
                        glyph: tokens.glyphMoon,
                        label: "Night Light",
                        active: root.nightLightEnabled
                    }
                ]

                delegate: Column {
                    id: toggleCell

                    required property var modelData

                    width: toggleRow.cellWidth
                    spacing: 6

                    IslandCircleButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: 42
                        implicitHeight: 42
                        glyphSize: 18
                        glyph: toggleCell.modelData.glyph
                        iconFontFamily: root.iconFontFamily
                        active: toggleCell.modelData.active
                        onActivated: root.handleToggle(toggleCell.modelData.key)
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: toggleCell.modelData.label
                        color: tokens.fg50
                        font.family: root.textFontFamily
                        font.pixelSize: 10
                    }
                }
            }
        }

        // --- Sliders -------------------------------------------------------
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 8

            IslandCapsuleSlider {
                width: parent.width
                value: root.volumeValue
                glyph: root.volumeValue > 0.5 ? tokens.glyphVolume : tokens.glyphVolumeLow
                iconFontFamily: root.iconFontFamily
                textFontFamily: root.textFontFamily
                onMoved: (next) => {
                    root.volumeValue = next;
                    volumeApply.restart();
                }
                onReleased: (next) => {
                    root.volumeValue = next;
                    SystemServices.setVolume(next);
                }
            }

            IslandCapsuleSlider {
                width: parent.width
                value: root.brightnessValue
                glyph: tokens.glyphSun
                iconFontFamily: root.iconFontFamily
                textFontFamily: root.textFontFamily
                onMoved: (next) => {
                    root.brightnessValue = next;
                    brightnessApply.restart();
                }
                onReleased: (next) => {
                    root.brightnessValue = next;
                    SystemServices.setBrightness(next);
                }
            }
        }
    }

    function handleToggle(key) {
        if (key === "wifi") {
            if (root.wifiController) root.wifiController.setEnabled(!root.wifiEnabled);
        } else if (key === "bluetooth") {
            if (root.bluetoothAdapter) root.bluetoothAdapter.enabled = !root.bluetoothEnabled;
        } else if (key === "mic") {
            micToggleProcess.running = true;
        } else if (key === "night") {
            root.nightLightEnabled = !root.nightLightEnabled;
            nightLightProcess.enable = root.nightLightEnabled;
            nightLightProcess.running = true;
        }
    }
}
