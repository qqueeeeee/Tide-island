import QtQuick
import TideIsland 1.0

Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "Live preview"

        IslandPreview {
            width: parent.width
        }
    }

    UiCard {
        width: parent.width
        title: "Spacing"
        caption: "The bar is invisible on purpose — these values control how its items sit around the island."

        UiSlider {
            label: "Screen edge margin"
            hint: "Space between the screen edges and the outermost bar items."
            configKey: "statusBarSideMargin"
            from: 0
            to: 120
        }

        UiSlider {
            label: "Gap next to the island"
            hint: "Minimum distance kept between the capsule and the nearest bar item."
            configKey: "statusBarIslandGap"
            from: 0
            to: 120
        }

        UiSlider {
            label: "Spacing between items"
            configKey: "statusBarItemSpacing"
            from: 0
            to: 48
        }

        UiSlider {
            label: "Vertical offset"
            hint: "Nudge bar text up or down relative to the island's centre line."
            configKey: "statusBarBaselineOffset"
            from: -20
            to: 40
        }

        UiSlider {
            label: "Bar opacity"
            configKey: "statusBarOpacity"
            from: 20
            to: 100
            suffix: " %"
        }
    }

    UiCard {
        width: parent.width
        title: "Items"

        UiSwitch {
            label: "Show the status bar"
            configKey: "statusBarEnabled"
        }

        UiSwitch {
            label: "Workspace dots"
            configKey: "statusBarShowWorkspaces"
        }

        UiSwitch {
            label: "Focused window title"
            configKey: "statusBarShowActiveWindow"
        }

        UiSwitch {
            label: "Battery, Wi-Fi and mute icons"
            configKey: "statusBarShowStatusIcons"
        }

        UiSwitch {
            label: "Clock"
            configKey: "statusBarShowClock"
        }

        UiSwitch {
            label: "Show the date when hovering the clock"
            configKey: "statusBarShowDateOnHover"
        }

        UiSwitch {
            label: "Dim the bar while the island is busy"
            hint: "macOS behaviour: bar items stay put and just fade back a touch."
            configKey: "statusBarFadeWithIsland"
        }

        UiSegment {
            label: "Clock format"
            configKey: "clockFormat"
            options: [
                { label: "12-hour", value: "12" },
                { label: "24-hour", value: "24" }
            ]
        }
    }

    Row {
        spacing: 10

        UiButton {
            text: "Reset bar layout"
            onClicked: ConfigStore.resetKeys([
                "statusBarSideMargin",
                "statusBarIslandGap",
                "statusBarItemSpacing",
                "statusBarBaselineOffset",
                "statusBarOpacity"
            ])
        }
    }
}
