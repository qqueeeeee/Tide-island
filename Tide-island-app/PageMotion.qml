import QtQuick
import TideIsland 1.0

// Motion tuning: island spring physics presets, press/pulse feedback and the
// idle capsule's resting look.
Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "Motion preset"
        caption: "Snappy and bouncy tweak the spring/damping pairs behind the scenes. Pick Custom to dial in your own."

        UiSegment {
            label: "Preset"
            configKey: "motionPreset"
            options: [
                { label: "Default", value: "default" },
                { label: "Snappy", value: "snappy" },
                { label: "Bouncy", value: "bouncy" },
                { label: "Custom", value: "custom" }
            ]
        }
    }

    UiCard {
        width: parent.width
        visible: ConfigStore.value("motionPreset") === "custom"
        title: "Advanced springs"
        caption: "Only used while the preset above is set to Custom."

        UiSlider {
            label: "Shape spring"
            hint: "Stored as x10 (36 = 3.6)."
            configKey: "motionShapeSpring"
            from: 10
            to: 120
            suffix: ""
        }

        UiSlider {
            label: "Shape damping"
            hint: "Stored as x100 (42 = 0.42)."
            configKey: "motionShapeDamping"
            from: 10
            to: 100
            suffix: ""
        }

        UiSlider {
            label: "Radius spring"
            configKey: "motionRadiusSpring"
            from: 10
            to: 120
            suffix: ""
        }

        UiSlider {
            label: "Radius damping"
            configKey: "motionRadiusDamping"
            from: 10
            to: 100
            suffix: ""
        }

        UiSlider {
            label: "Content reveal duration"
            configKey: "motionContentRevealDuration"
            from: 60
            to: 600
            suffix: " ms"
        }
    }

    UiCard {
        width: parent.width
        title: "Touch feedback"

        UiSlider {
            label: "Press scale"
            hint: "How much the island shrinks while pressed."
            configKey: "motionPressScale"
            from: 85
            to: 100
            suffix: " %"
        }

        UiSlider {
            label: "Pulse scale"
            hint: "How much the island grows for the acknowledgement pulse."
            configKey: "motionPulseScale"
            from: 100
            to: 125
            suffix: " %"
        }

        UiSlider {
            label: "Long-press duration"
            configKey: "motionLongPressMs"
            from: 150
            to: 1200
            suffix: " ms"
        }
    }

    UiCard {
        width: parent.width
        title: "Idle capsule"
        caption: "The look of the island when nothing is happening."

        UiSegment {
            label: "Idle style"
            configKey: "idleStyle"
            options: [
                { label: "Dot", value: "dot" },
                { label: "Orb", value: "orb" },
                { label: "Clock", value: "clock" },
                { label: "Blank", value: "blank" }
            ]
        }

        UiSlider {
            label: "Dot size"
            visible: ConfigStore.value("idleStyle") === "dot"
            configKey: "idleDotSize"
            from: 2
            to: 16
        }

        UiSlider {
            label: "Dot opacity"
            visible: ConfigStore.value("idleStyle") === "dot"
            configKey: "idleDotOpacity"
            from: 5
            to: 100
            suffix: " %"
        }

        UiSwitch {
            label: "Show usage rings"
            hint: "A subtle ring around the idle capsule reflecting system load."
            configKey: "idleShowUsageRings"
        }

        UiSwitch {
            label: "Idle breathing animation"
            configKey: "motionIdleBreathEnabled"
        }
    }

    Row {
        spacing: 10

        UiButton {
            text: "Reset motion"
            onClicked: ConfigStore.resetKeys([
                "motionPreset",
                "motionShapeSpring",
                "motionShapeDamping",
                "motionRadiusSpring",
                "motionRadiusDamping",
                "motionContentRevealDuration",
                "motionPressScale",
                "motionPulseScale",
                "motionLongPressMs",
                "motionIdleBreathEnabled",
                "idleStyle",
                "idleShowUsageRings",
                "idleDotSize",
                "idleDotOpacity"
            ])
        }
    }
}
