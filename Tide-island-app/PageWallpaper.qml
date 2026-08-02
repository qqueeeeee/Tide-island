import QtQuick
import TideIsland 1.0

// Wallpaper settings. The built-in apply flow (target copy, library, pywal,
// transition) is disabled while a custom command is in charge, and vice versa.
Column {
    id: root

    readonly property bool customCommandActive: ConfigStore.flag("wallpaperCustomCommandEnabled")

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
