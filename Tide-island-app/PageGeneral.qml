import QtQuick
import TideIsland 1.0

Column {
    spacing: 14

    UiCard {
        id: startupCard

        property bool serviceEnabled: backend.autostartEnabled()

        width: parent.width
        title: "Startup"
        caption: backend.autostartSummary()

        UiSwitch {
            label: "Launch Tide Island at login"
            hint: "Enables the tide-island systemd user service."
            configKey: "shellAutostartEnabled"
            enabled: backend.autostartAvailable()
            onToggled: (value) => {
                if (!backend.setAutostartEnabled(value)) {
                    ConfigStore.set("shellAutostartEnabled", !value);
                    ConfigStore.status = backend.errorString;
                    return;
                }
                startupCard.serviceEnabled = value;
                ConfigStore.status = value ? "Autostart enabled" : "Autostart disabled";
            }
        }
    }


    UiCard {
        width: parent.width
        title: "Island monitor"
        caption: "Choose which monitor(s) show the island."

        UiSegment {
            label: "Monitor mode"
            configKey: "islandMonitorMode"
            options: [
                { label: "All", value: "all" },
                { label: "Primary", value: "primary" },
                { label: "Named", value: "named" }
            ]
        }

        UiTextField {
            label: "Monitor name"
            hint: "Used when monitor mode is set to Named, e.g. DP-1."
            visible: ConfigStore.value("islandMonitorMode") === "named"
            configKey: "islandMonitorName"
            placeholder: "DP-1"
        }
    }

    UiCard {
        width: parent.width
        title: "Status bar monitor"

        UiSegment {
            label: "Monitor mode"
            configKey: "statusBarMonitorMode"
            options: [
                { label: "All", value: "all" },
                { label: "Primary", value: "primary" },
                { label: "Named", value: "named" }
            ]
        }

        UiTextField {
            label: "Monitor name"
            hint: "Used when monitor mode is set to Named, e.g. DP-1."
            visible: ConfigStore.value("statusBarMonitorMode") === "named"
            configKey: "statusBarMonitorName"
            placeholder: "DP-1"
        }
    }

    UiCard {
        width: parent.width
        title: "Config file"
        caption: "The same actions live on the About page."

        Item {
            width: parent.width
            height: 44

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 200
                text: ConfigStore.path
                elide: Text.ElideMiddle
                color: AppTheme.textDim
                font.family: "monospace"
                font.pixelSize: 12
            }

            UiButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Copy config path"
                onClicked: {
                    backend.copyToClipboard(ConfigStore.path);
                    ConfigStore.status = "Config path copied";
                }
            }
        }
    }
}
