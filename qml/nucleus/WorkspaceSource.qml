pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

// Live workspace overview data. `hyprctl -j clients` gives real window geometry,
// which is normalised per monitor into the fractional rects the React reference
// tiles expect: { id, name, windows: [{ title, x, y, w, h, tint }] }
Item {
    id: root

    property int count: 9
    property var workspaces: []
    readonly property int active: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    readonly property var tints: [
        ["#a25bd6", "#5b3f9e"],
        ["#e8654a", "#8a3325"],
        ["#f0a93a", "#8a6318"],
        ["#3fa9d8", "#245a86"],
        ["#43c98a", "#1f6b4c"]
    ]

    visible: false
    width: 0
    height: 0

    Component.onCompleted: root.rebuild()

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = String(event.name);
            if (name === "openwindow" || name === "closewindow" || name === "movewindow"
                || name === "workspace" || name === "focusedmon" || name === "fullscreen")
                refreshDebounce.restart();
        }
    }

    Timer {
        id: refreshDebounce

        interval: 90
        onTriggered: root.rebuild()
    }

    function rebuild() {
        clients.running = false;
        clients.running = true;
    }

    function switchTo(id) {
        Hyprland.dispatch("workspace " + id);
    }

    function buildFrom(clientList, monitorList) {
        // Monitor bounds are used to convert absolute window positions into
        // 0..1 tile coordinates.
        const monitors = ({});
        for (let index = 0; index < monitorList.length; ++index) {
            const monitor = monitorList[index];
            monitors[String(monitor.name)] = {
                x: monitor.x,
                y: monitor.y,
                width: Math.max(1, monitor.width / (monitor.scale ? monitor.scale : 1)),
                height: Math.max(1, monitor.height / (monitor.scale ? monitor.scale : 1))
            };
        }

        const byWorkspace = ({});
        for (let index = 0; index < clientList.length; ++index) {
            const client = clientList[index];
            if (!client || client.hidden || !client.mapped || !client.workspace)
                continue;

            const workspaceId = client.workspace.id;
            if (workspaceId < 1 || workspaceId > root.count)
                continue;

            const monitor = monitors[String(client.monitor >= 0 && monitorList[client.monitor]
                ? monitorList[client.monitor].name
                : "")]
                || monitors[Object.keys(monitors)[0]]
                || { x: 0, y: 0, width: 1920, height: 1080 };

            const at = client.at ? client.at : [0, 0];
            const size = client.size ? client.size : [0, 0];

            const entry = {
                title: String(client.title ? client.title : client.class),
                x: Math.max(0, Math.min(0.96, (at[0] - monitor.x) / monitor.width)),
                y: Math.max(0, Math.min(0.94, (at[1] - monitor.y) / monitor.height)),
                w: Math.max(0.04, Math.min(1, size[0] / monitor.width)),
                h: Math.max(0.04, Math.min(1, size[1] / monitor.height)),
                tint: root.tints[index % root.tints.length]
            };

            if (byWorkspace[workspaceId] === undefined)
                byWorkspace[workspaceId] = [];
            byWorkspace[workspaceId].push(entry);
        }

        const built = [];
        for (let id = 1; id <= root.count; ++id) {
            const windows = byWorkspace[id] ? byWorkspace[id] : [];
            built.push({
                id: id,
                name: windows.length > 0 ? windows[0].title : "empty",
                windows: windows
            });
        }
        root.workspaces = built;
    }

    Process {
        id: clients

        command: ["sh", "-c", "hyprctl -j clients; echo '@@'; hyprctl -j monitors"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = String(this.text).split("@@");
                if (parts.length < 2)
                    return;
                try {
                    root.buildFrom(JSON.parse(parts[0]), JSON.parse(parts[1]));
                } catch (error) {
                    console.log("[WorkspaceSource] failed to parse hyprctl output: " + error);
                }
            }
        }
    }
}
