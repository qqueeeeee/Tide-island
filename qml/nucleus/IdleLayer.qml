pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend
import "../island" as Island

// Idle (resting) content for the capsule. Reference default is a 6px dot at
// 25% white, pinned right; `idleStyle` lets it be swapped for the legacy orb
// visualisation, a minimal clock, or nothing at all.
Item {
    id: root

    readonly property var userConfig: UserConfig
    readonly property string idleStyle: userConfig.idleStyle
    readonly property bool showUsageRings: userConfig.idleShowUsageRings

    property bool showCondition: true
    property real revealOffset: 0
    property string textFontFamily: ""
    property string heroFontFamily: ""

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    // --- CPU/RAM polling, only spun up for the orb + usage-rings combo -----
    property real cpuUsage: -1
    property real ramUsage: -1
    readonly property bool needsSystemStats: root.idleStyle === "orb" && root.showUsageRings

    Timer {
        interval: 2500
        repeat: true
        running: root.needsSystemStats
        triggeredOnStart: true
        onTriggered: SystemServices.requestSystemStats()
    }

    Connections {
        target: SystemServices
        enabled: root.needsSystemStats

        function onSystemStatsReady(cpu, ram, errorString) {
            if (errorString !== "")
                return;
            if (cpu >= 0) root.cpuUsage = cpu;
            if (ram >= 0) root.ramUsage = ram;
        }
    }

    // --- dot ------------------------------------------------------------
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: root.idleStyle === "dot" || root.idleStyle === ""
        width: Math.max(2, Math.min(16, root.userConfig.idleDotSize))
        height: width
        radius: width / 2
        color: "#ffffff"
        opacity: Math.max(0.05, Math.min(1, root.userConfig.idleDotOpacity / 100))
    }

    // --- orb (reuses the legacy living-orb layer; rings only when enabled) -
    Loader {
        anchors.fill: parent
        active: root.idleStyle === "orb" && root.showUsageRings
        visible: active
        sourceComponent: Island.IslandOrbLayer {
            cpuUsage: root.cpuUsage
            ramUsage: root.ramUsage
            showCondition: root.showCondition
        }
    }

    // Ring-less orb: same living core, no CPU/RAM satellites.
    Item {
        visible: root.idleStyle === "orb" && !root.showUsageRings
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Math.max(12, root.height * 0.4)
        width: Math.max(12, Math.min(20, root.height * 0.46))
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#f2f6ff" }
                GradientStop { position: 1.0; color: "#7f8ea6" }
            }

            SequentialAnimation on opacity {
                running: root.showCondition
                loops: Animation.Infinite
                NumberAnimation { to: 1.0; duration: 2200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.78; duration: 2600; easing.type: Easing.InOutSine }
            }
        }
    }

    // --- clock ------------------------------------------------------------
    Loader {
        anchors.fill: parent
        active: root.idleStyle === "clock"
        visible: active
        sourceComponent: ClockPeekLayer {
            textFontFamily: root.textFontFamily
            heroFontFamily: root.heroFontFamily
            showCondition: root.showCondition
            lifeProgress: 1
        }
    }

    // --- blank --------------------------------------------------------------
    // Nothing drawn; the capsule itself is the only signal it is alive.
}
