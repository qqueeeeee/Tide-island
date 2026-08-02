import QtQuick
import TideIsland 1.0

Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "Tide Island"
        caption: "An iOS-style Dynamic Island and invisible status bar for Hyprland."

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

    UiCard {
        width: parent.width
        title: "Opening this window"

        Repeater {
            model: [
                "Press SUPER + comma",
                "Click the gear in the island's Control Centre",
                "Run: quickshell ipc call settings open",
                "Launch \"Tide Island Settings\" from your app launcher"
            ]

            delegate: Item {
                required property string modelData

                width: parent.width
                height: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "•  " + modelData
                    color: AppTheme.textDim
                    font.family: AppTheme.fontFamily
                    font.pixelSize: 12
                }
            }
        }
    }

    UiCard {
        width: parent.width
        title: "Danger zone"

        Row {
            spacing: 10

            UiButton {
                text: "Restore every default"
                destructive: true
                onClicked: {
                    const keys = Object.keys(ConfigStore.defaults);
                    ConfigStore.resetKeys(keys);
                    ConfigStore.status = "Defaults restored";
                }
            }
        }
    }
}
