pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Shared motion tokens for the Dynamic Island.
//
// Everything that morphs (capsule width/height/radius, content reveals, button
// feedback) reads its timing from here so the whole surface moves as one object
// instead of a set of independently tuned animations.
//
// The shape uses SpringAnimation rather than a duration curve: Apple's island
// settles with a small, quick overshoot that depends on how far it travelled,
// which is exactly what a critically-underdamped spring does for free.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    readonly property var userConfig: UserConfig
    readonly property string preset: userConfig.motionPreset

    // --- Preset resolution ---------------------------------------------
    // preset != "custom" overrides the raw config numbers with the table
    // from the spec: snappy = shape 52/62, radius 60/85;
    // default = 36/42, 42/75; bouncy = 30/28, 34/55.
    readonly property int resolvedShapeSpringX10: {
        if (root.preset === "snappy") return 52;
        if (root.preset === "bouncy") return 30;
        if (root.preset === "default") return 36;
        return userConfig.motionShapeSpring;
    }
    readonly property int resolvedShapeDampingX100: {
        if (root.preset === "snappy") return 62;
        if (root.preset === "bouncy") return 28;
        if (root.preset === "default") return 42;
        return userConfig.motionShapeDamping;
    }
    readonly property int resolvedRadiusSpringX10: {
        if (root.preset === "snappy") return 60;
        if (root.preset === "bouncy") return 34;
        if (root.preset === "default") return 42;
        return userConfig.motionRadiusSpring;
    }
    readonly property int resolvedRadiusDampingX100: {
        if (root.preset === "snappy") return 85;
        if (root.preset === "bouncy") return 55;
        if (root.preset === "default") return 75;
        return userConfig.motionRadiusDamping;
    }

    // --- Shape springs -----------------------------------------------------
    // Width/height: lively, slight overshoot (~4-6%), settles in ~400ms.
    readonly property real shapeSpring: root.resolvedShapeSpringX10 / 10
    readonly property real shapeDamping: root.resolvedShapeDampingX100 / 100
    readonly property real shapeMass: 1.0
    // Pixel-sized properties: stop animating once we are visually there.
    readonly property real shapeEpsilon: 0.25

    // Corner radius follows the shape but with more damping, so corners do not
    // visibly wobble while the pill unfolds into a card.
    readonly property real radiusSpring: root.resolvedRadiusSpringX10 / 10
    readonly property real radiusDamping: root.resolvedRadiusDampingX100 / 100
    readonly property real radiusEpsilon: 0.15

    // Nominal settle time. Springs are duration-less, but a few sequencing
    // timers still need "how long until the shape is basically done".
    readonly property int settleDuration: 420

    // --- Content sequencing ------------------------------------------------
    // Old content leaves fast and completely...
    readonly property int contentExitDuration: 100
    // ...the shape morphs...
    readonly property int contentRevealDelay: 110
    // ...then the new content fades and slides up into place.
    readonly property int contentRevealDuration: userConfig.motionContentRevealDuration
    readonly property real contentRevealOffset: 7

    // --- Interactive feedback ---------------------------------------------
    readonly property real buttonSpring: 6.0
    readonly property real buttonDamping: 0.35
    readonly property int buttonColorDuration: 140

    // The whole capsule reacts to being touched, not just its contents: press
    // sinks it slightly, an in-place content update gives it a single quick
    // pulse. Both ride the same spring family as the shape morph so nothing
    // feels bolted on.
    readonly property real pressScale: userConfig.motionPressScale / 100
    readonly property real pulseScale: userConfig.motionPulseScale / 100
    readonly property int pulseAttackDuration: 120
    readonly property int longPressInterval: userConfig.motionLongPressMs

    // --- Idle breath -------------------------------------------------------
    // Barely-there life sign for the empty idle pill: several seconds per cycle,
    // ~1% of scale. If you can see it happening it is too strong.
    readonly property bool idleBreathEnabled: userConfig.motionIdleBreathEnabled
    readonly property real idleBreathScale: 1.012
    readonly property real idleBreathOpacity: 0.93
    readonly property int idleBreathDuration: 2600
}
