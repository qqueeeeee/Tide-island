import QtQuick
import TideIsland 1.0

Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "App filters"
        caption: "If the allow list is empty, every app is allowed."

        UiTagList {
            label: "Allowed apps"
            hint: "Empty = all allowed."
            configKey: "notificationsAllowedApps"
            placeholder: "app id"
        }

        UiTagList {
            label: "Blocked apps"
            configKey: "notificationsBlockedApps"
            placeholder: "app id"
        }
    }

    UiCard {
        width: parent.width
        title: "Do not disturb"

        UiSwitch {
            label: "Do not disturb"
            hint: "Suppresses notification cards on the island while enabled."
            configKey: "doNotDisturbEnabled"
        }

        UiSwitch {
            label: "Schedule"
            hint: "Automatically enable do-not-disturb during a fixed window each day."
            configKey: "dndScheduleEnabled"
        }

        UiTimeField {
            label: "Start"
            configKey: "dndStartTime"
        }

        UiTimeField {
            label: "End"
            configKey: "dndEndTime"
        }
    }

    UiCard {
        width: parent.width
        title: "History"

        UiSlider {
            label: "History limit"
            configKey: "notificationsHistoryLimit"
            from: 5
            to: 200
        }
    }

    Row {
        spacing: 10

        UiButton {
            text: "Reset notifications"
            onClicked: ConfigStore.resetKeys([
                "notificationsBlockedApps",
                "notificationsAllowedApps",
                "doNotDisturbEnabled",
                "dndScheduleEnabled",
                "dndStartTime",
                "dndEndTime",
                "notificationsHistoryLimit"
            ])
        }
    }
}
