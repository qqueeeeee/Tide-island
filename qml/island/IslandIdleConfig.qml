pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Idle (no live activity) content policy for the island.
//
// The real Dynamic Island shows *nothing* when idle — it is just a quiet piece
// of hardware that breathes with the desktop. That is the default here too.
// Swap `idleContent` to change what the resting capsule holds without touching
// any layout code:
//
//   "orb"       — living orb on the left with CPU/RAM satellite rings (default)
//   "breathing" — empty pill, very slow scale/opacity breath
//   "glance"    — a single tiny dot; click expands into the system glance
//   "clock"     — minimal low-opacity time, no seconds, no visual weight
//
// If the C++ UserConfig ever grows an `islandIdleContent` string, it wins, so
// the settings app can drive this without another QML change.
Item {
    id: root

    readonly property var userConfig: UserConfig

    visible: false
    width: 0
    height: 0

    // Change this line (or set userConfig.islandIdleContent) to swap idle style.
    property string preferredIdleContent: "orb"

    readonly property string configuredIdleContent: {
        const fromBackend = root.userConfig && root.userConfig.islandIdleContent !== undefined
            ? String(root.userConfig.islandIdleContent)
            : "";
        return fromBackend !== "" ? fromBackend : root.preferredIdleContent;
    }

    readonly property string idleContent: {
        switch (root.configuredIdleContent) {
        case "orb":
        case "glance":
        case "clock":
        case "breathing":
            return root.configuredIdleContent;
        default:
            return "orb";
        }
    }

    readonly property bool idleBreathes: idleContent === "breathing"
    readonly property bool idleShowsGlanceDot: idleContent === "glance"
    readonly property bool idleShowsClockText: idleContent === "clock"
    readonly property bool idleShowsOrb: idleContent === "orb"
}
