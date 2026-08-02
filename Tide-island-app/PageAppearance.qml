import QtQuick
import TideIsland 1.0

Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "Settings app"

        UiSegment {
            label: "Appearance"
            hint: "Only affects this window."
            options: [
                { label: "Dark", value: "dark" },
                { label: "Light", value: "light" }
            ]
            currentValue: backend.colorScheme
            onSelected: (value) => backend.setColorScheme(String(value))
        }
    }

    UiCard {
        width: parent.width
        title: "Fonts"
        caption: "Use the exact family name as installed, e.g. \"Inter Display\" or \"SF Pro Display\"."

        UiTextField {
            label: "Interface font"
            configKey: "textFontFamily"
            placeholder: "Inter Display"
        }

        UiTextField {
            label: "Hero font"
            hint: "Large numerals: timers, now-playing titles."
            configKey: "heroFontFamily"
            placeholder: "Inter Display"
        }

        UiTextField {
            label: "Clock font"
            configKey: "timeFontFamily"
            placeholder: "Inter Display"
        }

        UiTextField {
            label: "Icon font"
            hint: "Needs a Nerd Font for the glyphs used by the island."
            configKey: "iconFontFamily"
            placeholder: "JetBrainsMono Nerd Font"
        }
    }

    UiCard {
        width: parent.width
        title: "Sizes"

        UiSlider {
            label: "Body text"
            configKey: "bodyFontSize"
            from: 10
            to: 24
        }

        UiSlider {
            label: "Titles"
            configKey: "titleFontSize"
            from: 12
            to: 32
        }

        UiSlider {
            label: "Icons"
            configKey: "iconFontSize"
            from: 10
            to: 30
        }
    }
}
