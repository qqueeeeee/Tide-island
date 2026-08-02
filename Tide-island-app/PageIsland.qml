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

        UiSwitch {
            label: "Set the height in pixels"
            hint: "On: the island is sized by the exact height below and the scale slider is ignored."
            configKey: "islandHeightOverrideEnabled"
        }

        UiNumberField {
            label: "Island height"
            hint: "Idle capsule height. The reference iOS size is 37 px; everything scales from it."
            configKey: "islandHeight"
            minimum: 20
            maximum: 96
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

    UiCard {
        width: parent.width
        title: "Exact numbers"
        caption: "Type precise pixel values instead of dragging sliders."

        UiNumberField {
            label: "Top margin"
            configKey: "islandTopMargin"
            minimum: 0
            maximum: 200
        }

        UiNumberField {
            label: "Gap below the island"
            configKey: "islandBottomGap"
            minimum: 0
            maximum: 200
        }

        UiNumberField {
            label: "Corner radius cap"
            configKey: "islandCornerRadius"
            minimum: 4
            maximum: 60
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
                "islandHeight",
                "islandHeightOverrideEnabled",
                "islandCornerRadius",
                "islandBackgroundOpacity"
            ])
        }
    }
}
