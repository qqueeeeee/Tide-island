import QtQuick
import QtQuick.Dialogs
import TideIsland 1.0

// Wallpaper settings. The built-in apply flow (target copy, library, pywal,
// transition) is disabled while a custom command is in charge, and vice versa.
Column {
    id: root

    readonly property bool customCommandActive: ConfigStore.flag("wallpaperCustomCommandEnabled")

    property string libraryDirectory: ""
    property string appliedPath: ""

    function reloadLibrary() {
        root.libraryDirectory = backend.wallpaperLibraryDirectory();
        wallpaperModel.clear();
        const entries = backend.wallpaperEntries();
        for (let index = 0; index < entries.length; index++)
            wallpaperModel.append({ name: String(entries[index].name), path: String(entries[index].path) });
    }

    function apply(path) {
        if (backend.applyWallpaper(path)) {
            root.appliedPath = path;
            ConfigStore.status = "Wallpaper applied";
        } else {
            ConfigStore.status = backend.errorString;
        }
    }

    Component.onCompleted: root.reloadLibrary()

    ListModel {
        id: wallpaperModel
    }

    readonly property var transitionTypes: [
        "none", "simple", "fade", "left", "right", "top", "bottom",
        "wipe", "wave", "grow", "center", "any", "outer", "random"
    ]

    spacing: 14

    // Wraps rows so a whole group can be dimmed/disabled in one place.
    component Gate: Item {
        property bool blocked: false
        default property alias content: inner.data

        width: parent ? parent.width : 0
        implicitHeight: inner.implicitHeight
        height: implicitHeight
        enabled: !blocked
        opacity: blocked ? 0.45 : 1

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        Column {
            id: inner
            width: parent.width
            spacing: 2
        }
    }

    FolderDialog {
        id: libraryDialog

        title: "Choose a wallpaper folder"
        onAccepted: {
            const path = String(selectedFolder).replace("file://", "");
            ConfigStore.set("wallpaperLibraryPath", decodeURIComponent(path));
            ConfigStore.flush();
            root.reloadLibrary();
        }
    }

    FileDialog {
        id: fileDialog

        title: "Choose a wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.avif *.jxl)"]
        onAccepted: {
            const path = decodeURIComponent(String(selectedFile).replace("file://", ""));
            root.apply(path);
        }
    }

    UiCard {
        width: parent.width
        title: "Wallpaper picker"
        caption: "Folder: " + (root.libraryDirectory === "" ? "not set" : root.libraryDirectory)

        Row {
            spacing: 10

            UiButton {
                text: "Choose folder…"
                onClicked: libraryDialog.open()
            }

            UiButton {
                text: "Pick a file…"
                onClicked: fileDialog.open()
            }

            UiButton {
                text: "Reload"
                onClicked: root.reloadLibrary()
            }
        }

        Text {
            width: parent.width
            visible: wallpaperModel.count === 0
            text: root.libraryDirectory === ""
                ? "Pick a folder to see your wallpapers here."
                : "No images found in " + root.libraryDirectory
            color: AppTheme.textFaint
            wrapMode: Text.WordWrap
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
        }

        GridView {
            id: grid

            width: parent.width
            visible: wallpaperModel.count > 0
            height: visible ? Math.min(430, Math.ceil(wallpaperModel.count / Math.max(1, Math.floor(width / cellWidth))) * cellHeight) : 0
            cellWidth: 176
            cellHeight: 116
            clip: true
            model: wallpaperModel

            delegate: Item {
                required property int index
                required property string name
                required property string path

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 12
                    color: AppTheme.dark ? "#101014" : "#f1f1f5"
                    border.width: root.appliedPath === path ? 2 : 1
                    border.color: root.appliedPath === path ? AppTheme.accent : AppTheme.cardBorder
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: "file://" + encodeURI(path)
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 340
                        smooth: true
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 22
                        color: "#000000aa"

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 7
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                            text: name
                            color: "#ffffff"
                            font.family: AppTheme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(path)
                    }
                }
            }
        }
    }

    UiCard {
        width: parent.width
        title: "Built-in wallpaper flow"
        caption: "Used by the island wallpaper picker. Leave the target empty to apply the selected file directly."

        Gate {
            blocked: root.customCommandActive

            UiTextField {
                label: "Wallpaper target"
                hint: "Stable copy path used by the workspace overview."
                configKey: "wallpaperPath"
                placeholder: "~/.cache/tide-island/current.png"
                fieldWidth: 300
            }

            UiTextField {
                label: "Wallpaper library"
                hint: "Folder scanned by the wallpaper picker."
                configKey: "wallpaperLibraryPath"
                placeholder: "~/Pictures/Wallpapers"
                fieldWidth: 300
            }

        }

        Gate {
            blocked: root.customCommandActive

            UiSwitch {
                label: "Run pywal after applying"
                hint: "Runs wal -n -q -i on the selected file once the wallpaper command succeeds."
                configKey: "wallpaperPywalEnabled"
            }
        }
    }

    UiCard {
        width: parent.width
        title: "Transition"
        caption: "awww wallpaper switch animation."

        Item {
            width: parent.width
            implicitHeight: transitionColumn.implicitHeight
            height: implicitHeight
            enabled: !root.customCommandActive
            opacity: root.customCommandActive ? 0.45 : 1

            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }

            Column {
                id: transitionColumn

                width: parent.width
                spacing: 2

                UiTextField {
                    label: "Transition type"
                    hint: "One of: " + root.transitionTypes.join(", ")
                    configKey: "wallpaperTransitionType"
                    placeholder: "center"
                    fieldWidth: 300
                }

                UiSlider {
                    label: "Transition duration"
                    configKey: "wallpaperTransitionDuration"
                    from: 1
                    to: 10
                    suffix: " s"
                }

                UiSlider {
                    label: "Transition frame rate"
                    configKey: "wallpaperTransitionFps"
                    from: 15
                    to: 144
                    suffix: " fps"
                }
            }
        }
    }

    UiCard {
        width: parent.width
        title: "Custom command"
        caption: "Replace the built-in flow with your own script. The selected wallpaper path is passed as $1."

        UiSwitch {
            label: "Use a custom command"
            configKey: "wallpaperCustomCommandEnabled"
        }

        Gate {
            blocked: !root.customCommandActive

            UiTextField {
                label: "Command"
                hint: "Bash; e.g. awww img \"$1\" --transition-type center"
                configKey: "wallpaperCustomCommand"
                placeholder: "awww img \"$1\""
                fieldWidth: 300
            }
        }
    }

    UiCard {
        width: parent.width
        title: "Reset"

        Gate {
            blocked: root.customCommandActive

            UiButton {
                text: "Reset built-in wallpaper settings"
                onClicked: ConfigStore.resetKeys([
                    "wallpaperPath",
                    "wallpaperLibraryPath",
                    "wallpaperPywalEnabled",
                    "wallpaperTransitionType",
                    "wallpaperTransitionDuration",
                    "wallpaperTransitionFps"
                ])
            }
        }
    }
}
