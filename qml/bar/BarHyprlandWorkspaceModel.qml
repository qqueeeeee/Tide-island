pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

// Occupied workspace ids for one monitor. Loaded lazily so niri sessions never
// touch the Hyprland IPC objects.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var screenObject: null

    readonly property var monitor: screenObject
        ? Hyprland.monitorFor(screenObject)
        : Hyprland.focusedMonitor
    readonly property string monitorName: monitor && monitor.name ? String(monitor.name) : ""
    readonly property var workspaceValues: Hyprland.workspaces ? Hyprland.workspaces.values : []
    property var workspaceIds: []
    // Focused workspace of this monitor, so a standalone bar surface does not
    // need the island window to tell it which workspace is active.
    property int activeWorkspaceId: 1

    function refreshActiveWorkspace() {
        const active = root.monitor && root.monitor.activeWorkspace
            ? root.monitor.activeWorkspace
            : null;
        const id = active ? Number(active.id) : NaN;
        if (isFinite(id) && id > 0 && id !== root.activeWorkspaceId)
            root.activeWorkspaceId = id;
    }


    function rebuild() {
        const ids = [];
        for (let index = 0; index < workspaceValues.length; index++) {
            const workspace = workspaceValues[index];
            if (!workspace)
                continue;

            const id = Number(workspace.id);
            if (!isFinite(id) || id <= 0)
                continue;

            const owner = workspace.monitor && workspace.monitor.name
                ? String(workspace.monitor.name)
                : "";
            if (root.monitorName !== "" && owner !== "" && owner !== root.monitorName)
                continue;

            if (ids.indexOf(id) === -1)
                ids.push(id);
        }

        ids.sort(function(left, right) { return left - right; });

        if (JSON.stringify(ids) !== JSON.stringify(root.workspaceIds))
            root.workspaceIds = ids;
    }

    onWorkspaceValuesChanged: rebuildTimer.restart()
    onMonitorNameChanged: rebuildTimer.restart()
    Component.onCompleted: {
        rebuild();
        refreshActiveWorkspace();
    }

    Timer {
        id: rebuildTimer
        interval: 60
        repeat: false
        onTriggered: {
            root.rebuild();
            root.refreshActiveWorkspace();
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const name = event && event.name ? String(event.name) : "";
            if (name.indexOf("workspace") !== -1 || name.indexOf("monitor") !== -1) {
                rebuildTimer.restart();
                root.refreshActiveWorkspace();
            }
        }
    }
}
