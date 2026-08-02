pragma ComponentBehavior: Bound

import QtQuick

// Resting ("nothing is happening") content for the island: a single living orb
// on the left of the pill with two satellite rings for CPU and RAM.
//
// The middle and right of the capsule are deliberately left empty — the resting
// island is an ambient object, not a dashboard. Motion is kept below the
// threshold where the eye tracks it: a slow drift, a slow glow breath, and rings
// that ease toward their new value instead of stepping.
Item {
    id: root

    // 0..1, -1 when unknown.
    property real cpuUsage: -1
    property real ramUsage: -1
    property bool showCondition: true
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    readonly property real clampedCpu: Math.max(0, Math.min(1, root.cpuUsage))
    readonly property real clampedRam: Math.max(0, Math.min(1, root.ramUsage))
    readonly property bool motionActive: root.showCondition && root.visible && root.opacity > 0.05

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Item {
        id: orbCluster

        readonly property real coreSize: Math.max(12, Math.min(20, root.height * 0.46))
        readonly property real satelliteSize: Math.max(9, orbCluster.coreSize * 0.62)

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Math.max(12, root.height * 0.4)
        width: coreSize + satelliteSize * 1.5
        height: Math.max(coreSize, satelliteSize * 2.1)

        // --- The living core -----------------------------------------------
        Item {
            id: core

            width: orbCluster.coreSize
            height: orbCluster.coreSize
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left

            // Gentle drift: two out-of-phase loops so the path never reads as a
            // straight back-and-forth.
            property real driftX: 0
            property real driftY: 0
            transform: Translate { x: core.driftX; y: core.driftY }

            SequentialAnimation on driftX {
                running: root.motionActive
                loops: Animation.Infinite
                NumberAnimation { to: 1.1; duration: 3100; easing.type: Easing.InOutSine }
                NumberAnimation { to: -1.1; duration: 3100; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on driftY {
                running: root.motionActive
                loops: Animation.Infinite
                NumberAnimation { to: -0.9; duration: 2300; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.9; duration: 2600; easing.type: Easing.InOutSine }
            }

            // Soft halo that breathes.
            Rectangle {
                id: halo

                anchors.centerIn: parent
                width: parent.width * 1.85
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Math.max(1, parent.width * 0.16)
                border.color: "#ffffff"
                opacity: 0.06

                SequentialAnimation on opacity {
                    running: root.motionActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.16; duration: 2100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.05; duration: 2600; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on scale {
                    running: root.motionActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.12; duration: 2400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.94; duration: 2800; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#f2f6ff" }
                    GradientStop { position: 1.0; color: "#7f8ea6" }
                }

                SequentialAnimation on opacity {
                    running: root.motionActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 2200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.78; duration: 2600; easing.type: Easing.InOutSine }
                }
            }
        }

        // --- CPU / RAM satellites -------------------------------------------
        // Stacked to the right of the core, so they read as companions of it
        // rather than as two unrelated indicators.
        IslandUsageRing {
            id: cpuRing

            size: orbCluster.satelliteSize
            value: root.clampedCpu
            known: root.cpuUsage >= 0
            ringColor: "#4cc2ff"
            anchors.left: core.right
            anchors.leftMargin: Math.max(3, orbCluster.coreSize * 0.22)
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: -orbCluster.satelliteSize * 0.06
            orbitPhase: 0
            motionActive: root.motionActive
        }

        IslandUsageRing {
            id: ramRing

            size: orbCluster.satelliteSize
            value: root.clampedRam
            known: root.ramUsage >= 0
            ringColor: "#ffd166"
            anchors.left: cpuRing.left
            anchors.top: parent.verticalCenter
            anchors.topMargin: orbCluster.satelliteSize * 0.06
            orbitPhase: 1
            motionActive: root.motionActive
        }
    }
}
