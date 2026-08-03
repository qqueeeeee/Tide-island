import QtQuick
import TideIsland 1.0

// Status bar page. Everything about the bar is adjustable here: height and
// baseline, spacing, typography, colours, per-item toggles, workspace dot
// metrics and an optional background plate.
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
        title: "Size & position"
        caption: "The bar owns its own surface, so its height is independent from the island."

        UiSwitch {
            label: "Show the status bar"
            configKey: "statusBarEnabled"
        }

        UiNumberField {
            label: "Bar height"
            hint: "Exact height of the bar strip in pixels."
            configKey: "statusBarHeight"
            minimum: 0
            maximum: 240
        }

        UiSlider {
            label: "Bar height (slider)"
            configKey: "statusBarHeight"
            from: 0
            to: 120
        }

        UiSwitch {
            label: "Align items to the island"
            hint: "On: bar items sit on the island's resting centre line. Off: they centre inside the bar height below."
            configKey: "statusBarUseIslandBaseline"
        }

        UiSlider {
            label: "Bar top margin"
            hint: "Only used when items are not aligned to the island."
            configKey: "statusBarTopMargin"
            from: 0
            to: 120
        }

        UiSlider {
            label: "Vertical offset"
            hint: "Nudge bar items up or down."
            configKey: "statusBarBaselineOffset"
            from: -40
            to: 120
        }
    }

    UiCard {
        width: parent.width
        title: "Spacing"

        UiSlider {
            label: "Screen edge margin"
            hint: "Space between the screen edges and the outermost bar items."
            configKey: "statusBarSideMargin"
            from: 0
            to: 200
        }

        UiSlider {
            label: "Gap next to the island"
            hint: "Minimum distance kept between the capsule and the nearest bar item."
            configKey: "statusBarIslandGap"
            from: 0
            to: 200
        }

        UiSlider {
            label: "Spacing between groups"
            configKey: "statusBarItemSpacing"
            from: 0
            to: 60
        }

        UiSlider {
            label: "Spacing between status icons"
            configKey: "statusBarIconSpacing"
            from: 0
            to: 40
        }
    }

    UiCard {
        width: parent.width
        title: "Typography"

        UiNumberField {
            label: "Text size"
            configKey: "statusBarFontSize"
            minimum: 7
            maximum: 40
        }

        UiNumberField {
            label: "Clock size"
            configKey: "statusBarClockFontSize"
            minimum: 7
            maximum: 40
        }

        UiNumberField {
            label: "Icon size"
            configKey: "statusBarIconSize"
            minimum: 7
            maximum: 40
        }

        UiSegment {
            label: "Text weight"
            configKey: "statusBarFontWeight"
            options: [
                { label: "Regular", value: 400 },
                { label: "Medium", value: 500 },
                { label: "Semibold", value: 600 },
                { label: "Bold", value: 700 }
            ]
        }

        UiSlider {
            label: "Text opacity"
            configKey: "statusBarTextOpacity"
            from: 10
            to: 100
            suffix: " %"
        }

        UiTextField {
            label: "Text colour"
            hint: "Any CSS/hex colour, e.g. #ffffff."
            configKey: "statusBarTextColor"
            placeholder: "#ffffff"
        }

        UiSwitch {
            label: "Text shadow"
            hint: "Keeps the transparent bar legible on light wallpapers."
            configKey: "statusBarTextShadow"
        }
    }

    UiCard {
        width: parent.width
        title: "Background"
        caption: "Off by default — the bar is meant to be invisible."

        UiSwitch {
            label: "Draw a background plate"
            configKey: "statusBarBackgroundEnabled"
        }

        UiTextField {
            label: "Background colour"
            configKey: "statusBarBackgroundColor"
            placeholder: "#000000"
        }

        UiSlider {
            label: "Background opacity"
            configKey: "statusBarBackgroundOpacity"
            from: 0
            to: 100
            suffix: " %"
        }

        UiSlider {
            label: "Background corner radius"
            configKey: "statusBarBackgroundRadius"
            from: 0
            to: 60
        }

        UiSlider {
            label: "Background side inset"
            configKey: "statusBarBackgroundMargin"
            from: 0
            to: 200
        }
    }

    UiCard {
        width: parent.width
        title: "Items"

        UiSwitch {
            label: "Workspace dots"
            configKey: "statusBarShowWorkspaces"
        }

        UiSwitch {
            label: "Focused window title"
            configKey: "statusBarShowActiveWindow"
        }

        UiSwitch {
            label: "Status icons"
            configKey: "statusBarShowStatusIcons"
        }

        UiSwitch {
            label: "Wi-Fi icon"
            configKey: "statusBarShowWifi"
        }

        UiSwitch {
            label: "Bluetooth icon"
            configKey: "statusBarShowBluetooth"
        }

        UiSwitch {
            label: "Mute icon"
            configKey: "statusBarShowMute"
        }

        UiSwitch {
            label: "Battery"
            configKey: "statusBarShowBattery"
        }

        UiSlider {
            label: "Battery size"
            configKey: "statusBarBatteryScale"
            from: 50
            to: 220
            suffix: " %"
        }

        UiSwitch {
            label: "Clock"
            configKey: "statusBarShowClock"
        }

        UiSwitch {
            label: "Seconds in the clock"
            configKey: "statusBarShowSeconds"
        }

        UiSwitch {
            label: "Always show the date"
            configKey: "statusBarShowDate"
        }

        UiSwitch {
            label: "Show the date when hovering the clock"
            configKey: "statusBarShowDateOnHover"
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

    UiCard {
        width: parent.width
        title: "Workspace dots"

        UiSlider {
            label: "Dot size"
            configKey: "statusBarWorkspaceDotSize"
            from: 2
            to: 28
        }

        UiSlider {
            label: "Active dot width"
            configKey: "statusBarWorkspaceActiveWidth"
            from: 4
            to: 80
        }

        UiSlider {
            label: "Dot spacing"
            configKey: "statusBarWorkspaceSpacing"
            from: 0
            to: 40
        }

        UiSlider {
            label: "Minimum dots"
            configKey: "statusBarWorkspaceMinimumCount"
            from: 1
            to: 10
            suffix: ""
        }
    }

    UiCard {
        width: parent.width
        title: "Window title & behaviour"

        UiSlider {
            label: "Title max width"
            hint: "0 keeps it automatic (fills the space left of the island)."
            configKey: "statusBarActiveWindowMaxWidth"
            from: 0
            to: 1600
        }

        UiSlider {
            label: "Title opacity"
            configKey: "statusBarActiveWindowOpacity"
            from: 20
            to: 100
            suffix: " %"
        }

        UiSlider {
            label: "Bar opacity"
            configKey: "statusBarOpacity"
            from: 0
            to: 100
            suffix: " %"
        }

        UiSwitch {
            label: "Dim the bar while the island is busy"
            hint: "macOS behaviour: bar items stay put and just fade back a touch."
            configKey: "statusBarFadeWithIsland"
        }

        UiSlider {
            label: "Dim amount"
            configKey: "statusBarDimAmount"
            from: 0
            to: 95
            suffix: " %"
        }
    }

    Row {
        spacing: 10

        UiButton {
            text: "Reset bar layout"
            onClicked: ConfigStore.resetKeys([
                "statusBarHeight",
                "statusBarUseIslandBaseline",
                "statusBarTopMargin",
                "statusBarSideMargin",
                "statusBarIslandGap",
                "statusBarItemSpacing",
                "statusBarIconSpacing",
                "statusBarBaselineOffset",
                "statusBarOpacity"
            ])
        }

        UiButton {
            text: "Reset bar style"
            onClicked: ConfigStore.resetKeys([
                "statusBarFontSize",
                "statusBarClockFontSize",
                "statusBarIconSize",
                "statusBarFontWeight",
                "statusBarTextOpacity",
                "statusBarTextColor",
                "statusBarTextShadow",
                "statusBarBackgroundEnabled",
                "statusBarBackgroundColor",
                "statusBarBackgroundOpacity",
                "statusBarBackgroundRadius",
                "statusBarBackgroundMargin",
                "statusBarWorkspaceDotSize",
                "statusBarWorkspaceActiveWidth",
                "statusBarWorkspaceSpacing",
                "statusBarWorkspaceMinimumCount",
                "statusBarBatteryScale",
                "statusBarActiveWindowMaxWidth",
                "statusBarActiveWindowOpacity",
                "statusBarDimAmount"
            ])
        }
    }
}
