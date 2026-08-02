import QtQuick
import TideIsland 1.0

Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "Live preview"
        caption: "Everything below updates the island instantly — no restart, no reload."

        IslandPreview {
            width: parent.width
        }
    }

    UiCard {
        width: parent.width
        title: "Placement"
        caption: "Where the capsule sits and how much room it leaves for your windows."

        UiSlider {
            label: "Top margin"
            hint: "Distance between the top of the screen and the island."
            configKey: "islandTopMargin"
            from: 0
            to: 60
        }

        UiSlider {
            label: "Gap below the island"
            hint: "Breathing room between the island and the top of your app windows."
            configKey: "islandBottomGap"
            from: 0
            to: 80
        }

        UiSwitch {
            label: "Reserve space for the island"
            hint: "On: windows tile below the island. Off: the island floats over full-height windows."
            configKey: "islandReserveSpace"
        }
    }

    UiCard {
        width: parent.width
        title: "Shape"
        caption: "Scale keeps the iOS layouts pixel-exact and just resizes the whole capsule."

        UiSlider {
            label: "Island scale"
            hint: "60–160% of the reference size."
            configKey: "islandScale"
            from: 60
            to: 160
            suffix: " %"
        }

        UiSlider {
            label: "Corner radius cap"
            hint: "Compact states stay fully round; this caps the radius of expanded cards."
            configKey: "islandCornerRadius"
            from: 4
            to: 60
        }

        UiSlider {
            label: "Background opacity"
            configKey: "islandBackgroundOpacity"
            from: 40
            to: 100
            suffix: " %"
        }
    }

    Row {
        spacing: 10

        UiButton {
            text: "Reset island layout"
            onClicked: ConfigStore.resetKeys([
                "islandTopMargin",
                "islandBottomGap",
                "islandReserveSpace",
                "islandScale",
                "islandCornerRadius",
                "islandBackgroundOpacity"
            ])
        }
    }
}
