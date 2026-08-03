import QtQuick
import TideIsland 1.0

Column {
    id: page

    spacing: 14

    property bool managedInstalled: false

    function reload() {
        page.managedInstalled = backend.managedShortcutsInstalled();
        bindingModel.clear();
        const bindings = backend.shortcutBindings();
        for (let index = 0; index < bindings.length; index++) {
            bindingModel.append({
                mods: String(bindings[index].mods),
                key: String(bindings[index].key),
                target: String(bindings[index].target),
                method: String(bindings[index].method)
            });
        }
    }

    function collect() {
        const list = [];
        for (let index = 0; index < bindingModel.count; index++) {
            const row = bindingModel.get(index);
            list.push({ mods: row.mods, key: row.key, target: row.target, method: row.method });
        }
        return list;
    }

    Component.onCompleted: page.reload()

    ListModel {
        id: bindingModel
    }

    UiCard {
        width: parent.width
        title: "Keyboard shortcuts"
        caption: "Compositor detected: " + backend.compositorDisplayName()
            + ". Saving stores the binds for Tide Island; copy the snippet or open your config to bind them."

        Repeater {
            model: bindingModel

            delegate: Item {
                id: row

                required property int index
                required property string mods
                required property string key
                required property string target
                required property string method

                width: parent.width
                height: 40

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: AppTheme.radiusControl
                    color: rowHover.hovered ? AppTheme.rowHover : "transparent"
                }

                HoverHandler { id: rowHover }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: removeButton.left
                    anchors.rightMargin: 10
                    spacing: 6

                    ShortcutField {
                        width: 116
                        text: row.mods
                        placeholder: "SUPER SHIFT"
                        onCommitted: (value) => bindingModel.setProperty(row.index, "mods", value)
                    }

                    ShortcutField {
                        width: 74
                        text: row.key
                        placeholder: "K"
                        onCommitted: (value) => bindingModel.setProperty(row.index, "key", value)
                    }

                    ShortcutField {
                        width: 96
                        text: row.target
                        placeholder: "island"
                        onCommitted: (value) => bindingModel.setProperty(row.index, "target", value)
                    }

                    ShortcutField {
                        width: 150
                        text: row.method
                        placeholder: "controlCenter"
                        onCommitted: (value) => bindingModel.setProperty(row.index, "method", value)
                    }
                }

                UiButton {
                    id: removeButton

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Remove"
                    destructive: true
                    onClicked: bindingModel.remove(row.index)
                }
            }
        }

        Row {
            spacing: 10

            UiButton {
                text: "Add shortcut"
                onClicked: bindingModel.append({ mods: "SUPER", key: "", target: "island", method: "controlCenter" })
            }

            UiButton {
                text: "Save shortcuts"
                primary: true
                onClicked: {
                    if (backend.saveShortcutBindings(page.collect())) {
                        ConfigStore.status = "Shortcuts saved. Add the snippet below to your compositor config.";
                        // Keep the shared snapshot in sync, otherwise the next
                        // slider change would write the old binds back.
                        ConfigStore.refresh();
                    } else {
                        ConfigStore.status = backend.errorString;
                    }
                    page.reload();
                }
            }

            UiButton {
                text: "Open config file"
                onClicked: {
                    if (backend.openPathInEditor(backend.shortcutConfigFilePath()))
                        ConfigStore.status = "Opened " + backend.shortcutConfigFilePath();
                    else
                        ConfigStore.status = backend.errorString;
                }
            }

            UiButton {
                text: "Copy snippet"
                onClicked: {
                    if (backend.copyToClipboard(backend.shortcutConfigSnippet(page.collect())))
                        ConfigStore.status = "Config snippet copied to the clipboard";
                    else
                        ConfigStore.status = backend.errorString;
                }
            }

            UiButton {
                text: "Reload"
                onClicked: page.reload()
            }
        }
    }

    UiCard {
        width: parent.width
        title: "Compositor binds"
        caption: backend.managedShortcutsSummary()

        Row {
            spacing: 10

            UiButton {
                text: page.managedInstalled ? "Remove managed binds" : "No managed binds installed"
                destructive: page.managedInstalled
                enabled: page.managedInstalled
                onClicked: {
                    if (backend.removeManagedShortcuts())
                        ConfigStore.status = "Removed the binds Tide Island had installed. Your own config now owns them.";
                    else
                        ConfigStore.status = backend.errorString;
                    page.reload();
                }
            }
        }
    }

    UiCard {
        width: parent.width
        title: "Available commands"
        caption: "Anything here can also be run manually: quickshell ipc call <target> <method>"

        Repeater {
            model: [
                { name: "island launcher", detail: "App launcher (search and run)" },
                { name: "island clipboard", detail: "Clipboard history with image previews" },
                { name: "island workspaces", detail: "Workspace overview grid" },
                { name: "island notifications", detail: "Notification centre" },
                { name: "island controlCenter", detail: "Wi-Fi, Bluetooth, mic, volume, brightness" },
                { name: "island close", detail: "Collapse whatever panel is open" },
                { name: "capture screenshotArea", detail: "Region screenshot with the island card" },
                { name: "capture toggleRecording", detail: "Start or stop screen recording" },
                { name: "settings open", detail: "Open this settings window" }
            ]

            delegate: Item {
                required property var modelData

                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: AppTheme.accent
                    font.family: "monospace"
                    font.pixelSize: 12
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.detail
                    color: AppTheme.textFaint
                    font.family: AppTheme.fontFamily
                    font.pixelSize: 12
                }
            }
        }
    }
}
