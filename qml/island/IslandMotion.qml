pragma ComponentBehavior: Bound

import QtQuick

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

    // --- Shape springs -----------------------------------------------------
    // Width/height: lively, slight overshoot (~4-6%), settles in ~400ms.
    readonly property real shapeSpring: 3.6
    readonly property real shapeDamping: 0.42
    readonly property real shapeMass: 1.0
    // Pixel-sized properties: stop animating once we are visually there.
    readonly property real shapeEpsilon: 0.25

    // Corner radius follows the shape but with more damping, so corners do not
    // visibly wobble while the pill unfolds into a card.
    readonly property real radiusSpring: 4.2
    readonly property real radiusDamping: 0.75
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
    readonly property int contentRevealDuration: 200
    readonly property real contentRevealOffset: 7

    // --- Interactive feedback ---------------------------------------------
    readonly property real buttonSpring: 6.0
    readonly property real buttonDamping: 0.35
    readonly property int buttonColorDuration: 140
}
