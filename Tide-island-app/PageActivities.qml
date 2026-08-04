import QtQuick
import TideIsland 1.0

// Live activities, transient card timing, the control centre's module order
// and media/clipboard sourcing.
Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "Live activity priority"
        caption: "Drag to reorder. The topmost activity that is currently active wins the island."

        UiOrderList {
            label: "Priority order"
            configKey: "liveActivityPriority"
            options: [
                { label: "Recording", value: "recording" },
                { label: "Media", value: "media" },
                { label: "Notification", value: "notification" },
                { label: "Call", value: "call" },
                { label: "Timer", value: "timer" }
            ]
        }
    }

    UiCard {
        width: parent.width
        title: "Transient card durations"
        caption: "How long each transient card stays expanded before collapsing back to idle."

        UiSlider {
            label: "Notification"
            configKey: "transientNotificationMs"
            from: 0
            to: 30000
            stepSize: 100
            suffix: " ms"
        }

        UiSlider {
            label: "Screenshot"
            configKey: "transientShotMs"
            from: 0
            to: 30000
            stepSize: 100
            suffix: " ms"
        }

        UiSlider {
            label: "Banner"
            configKey: "transientBannerMs"
            from: 0
            to: 30000
            stepSize: 100
            suffix: " ms"
        }

        UiSlider {
            label: "HUD"
            configKey: "transientHudMs"
            from: 0
            to: 30000
            stepSize: 100
            suffix: " ms"
        }

        UiSlider {
            label: "Clock"
            configKey: "transientClockMs"
            from: 0
            to: 30000
            stepSize: 100
            suffix: " ms"
        }

        UiSwitch {
            label: "Auto-expand notifications"
            configKey: "notificationAutoExpand"
        }
    }

    UiCard {
        width: parent.width
        title: "Control centre"

        UiOrderList {
            label: "Module order"
            hint: "Unknown modules are ignored."
            configKey: "controlCenterModules"
            options: [
                { label: "Wi-Fi", value: "wifi" },
                { label: "Bluetooth", value: "bluetooth" },
                { label: "Microphone", value: "mic" },
                { label: "Night light", value: "nightlight" },
                { label: "Do not disturb", value: "dnd" },
                { label: "Airplane mode", value: "airplane" }
            ]
        }

        UiSwitch {
            label: "Show volume slider"
            configKey: "controlCenterShowVolume"
        }

        UiSwitch {
            label: "Show brightness slider"
            configKey: "controlCenterShowBrightness"
        }
    }

    UiCard {
        width: parent.width
        title: "Media"

        UiTagList {
            label: "Excluded players"
            hint: "Lowercase substrings matched against the player's identity (e.g. \"firefox\")."
            configKey: "mediaExcludedPlayers"
            placeholder: "player name"
        }

        UiTagList {
            label: "Preferred players"
            hint: "Shown first when more than one player is active."
            configKey: "mediaPreferredPlayers"
            placeholder: "player name"
        }
    }

    UiCard {
        width: parent.width
        title: "Clipboard"

        UiSlider {
            label: "History limit"
            configKey: "clipboardHistoryLimit"
            from: 5
            to: 500
        }

        UiSwitch {
            label: "Show image previews"
            configKey: "clipboardShowImagePreviews"
        }

        UiTagList {
            label: "Excluded apps"
            configKey: "clipboardExcludedApps"
            placeholder: "app id"
        }
    }
}
