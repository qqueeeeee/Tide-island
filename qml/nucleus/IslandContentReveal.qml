pragma ComponentBehavior: Bound

import QtQuick

// Staggered reveal driver for island content layers.
//
// The island must never cross-fade two activities: the outgoing content leaves
// quickly, the capsule morphs, and only then does the new content fade + slide
// up into position. Layers opt in with three lines:
//
//     property real revealOffset: 0
//     transform: Translate { y: root.revealOffset }
//     IslandContentReveal { target: root; active: root.showCondition }
//
// The layer must NOT bind its own opacity (this object drives it).
Item {
    id: root

    property Item target: null
    property bool active: false

    property real offset: motion.contentRevealOffset
    property int revealDelay: motion.contentRevealDelay
    property int revealDuration: motion.contentRevealDuration
    property int hideDuration: motion.contentExitDuration

    visible: false
    width: 0
    height: 0

    IslandMotion { id: motion }

    onActiveChanged: root.restart()
    onTargetChanged: root.restart()

    Component.onCompleted: root.restart()

    function restart() {
        revealAnimation.stop();
        hideAnimation.stop();
        if (!target)
            return;

        if (active) {
            target.opacity = 0;
            target.revealOffset = offset;
            revealAnimation.start();
        } else {
            hideAnimation.start();
        }
    }

    SequentialAnimation {
        id: revealAnimation

        PauseAnimation { duration: root.revealDelay }

        ParallelAnimation {
            NumberAnimation {
                target: root.target
                property: "opacity"
                to: 1
                duration: root.revealDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root.target
                property: "revealOffset"
                to: 0
                duration: root.revealDuration
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }
    }

    SequentialAnimation {
        id: hideAnimation

        NumberAnimation {
            target: root.target
            property: "opacity"
            to: 0
            duration: root.hideDuration
            easing.type: Easing.InQuad
        }
        PropertyAction {
            target: root.target
            property: "revealOffset"
            value: root.offset
        }
    }
}
