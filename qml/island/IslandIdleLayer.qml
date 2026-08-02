pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// The resting layer for "nothing is happening".
//
// Apple's island is deliberately empty when idle, so the default mode renders
// no content at all and lets the capsule itself breathe (see the idle breath
// animation on the capsule). The other two modes are intentionally tiny: a
// glance dot, or a low-weight clock for shells with no bar clock elsewhere.
Item {
    id: root

    readonly property var userConfig: UserConfig

    // "orb" | "breathing" | "glance" | "clock"
    property string idleContent: "orb"
    // 0..1 system load, -1 when unknown. Only used by the "orb" mode.
    property real cpuUsage: -1
    property real ramUsage: -1
    property string currentTime: ""
    property string textFontFamily: ""
    property bool showCondition: true
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    // Orb mode: the living circle plus its CPU/RAM satellites. Owns its own
    // reveal, so it is mounted lazily and left alone by this layer's opacity.
    Loader {
        anchors.fill: parent
        active: root.idleContent === "orb"
        visible: active
        sourceComponent: IslandOrbLayer {
            cpuUsage: root.cpuUsage
            ramUsage: root.ramUsage
            showCondition: root.showCondition
        }
    }

    // Glance mode: a single unobtrusive dot. Clicking the capsule expands into
    // the full glance, exactly like tapping the real island.
    Rectangle {
        anchors.centerIn: parent
        visible: root.idleContent === "glance"
        width: 5
        height: 5
        radius: 2.5
        color: "#ffffff"
        opacity: 0.32
    }

    // Clock mode: minimal by design — no seconds, low opacity, light weight.
    Text {
        anchors.centerIn: parent
        visible: root.idleContent === "clock" && root.currentTime !== ""
        text: root.currentTime
        color: "#ffffff"
        opacity: 0.55
        font.family: root.textFontFamily
        font.pixelSize: Math.max(11, root.userConfig.bodyFontSize - 1)
        font.weight: Font.Medium
        font.letterSpacing: 0.2
    }
}
