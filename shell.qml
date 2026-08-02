import QtQuick
import Quickshell
import Quickshell.Io
import IslandBackend
import "qml/common"
import "qml/nucleus" as Nucleus

// Nucleus shell — the island capsule plus the transparent status bar, and
// nothing else. Built fresh on top of the React reference layouts rather than
// the older layered island shell.
Scope {
    id: shellRoot

    readonly property var userConfig: UserConfig
    readonly property var captureController: captureBackend

    CaptureController {
        id: captureBackend
    }

    function forEachIsland(callback) {
        const windows = islandVariants.instances ? islandVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            if (windows[index])
                callback(windows[index]);
        }
    }

    Connections {
        target: SystemServices

        function onNotificationReceived(appName, summary, body) {
            shellRoot.forEachIsland((island) => island.showNotification(appName, summary, body));
        }
    }

    IpcHandler {
        target: "island"

        function controlCenter() {
            shellRoot.forEachIsland((island) => island.toggleControlCentre());
        }

        function openControlCenter() {
            shellRoot.forEachIsland((island) => island.openControlCentre());
        }

        function closeControlCenter() {
            shellRoot.forEachIsland((island) => island.closeControlCentre());
        }

        function notify(summary, body) {
            shellRoot.forEachIsland((island) => island.showNotification("Tide", summary, body));
        }

        function volume(value) {
            const parsed = Number(value);
            shellRoot.forEachIsland((island) => island.showVolume(isNaN(parsed) ? 0 : parsed, false));
        }

        function launcher() {
            shellRoot.forEachIsland((island) => island.toggleLauncher());
        }

        function clipboard() {
            shellRoot.forEachIsland((island) => island.toggleClipboard());
        }

        function notifications() {
            shellRoot.forEachIsland((island) => island.toggleNotifications());
        }

        function workspaces() {
            shellRoot.forEachIsland((island) => island.toggleWorkspaces());
        }

        function close() {
            shellRoot.forEachIsland((island) => island.closePanel());
        }
    }


    IpcHandler {
        target: "tide"

        function toggleControlCenter() {
            shellRoot.forEachIsland((island) => island.toggleControlCentre());
        }
    }

    IpcHandler {
        target: "capture"

        function screenshot() {
            captureBackend.takeScreenshot("area");
        }

        function screenshotArea() {
            captureBackend.takeScreenshot("area");
        }

        function screenshotScreen() {
            captureBackend.takeScreenshot("screen");
        }

        function record() {
            captureBackend.startRecording(false);
        }

        function recordArea() {
            captureBackend.startRecording(true);
        }

        function stopRecording() {
            captureBackend.stopRecording();
        }

        function toggleRecording() {
            captureBackend.toggleRecording(false);
        }

        function toggleRecordingArea() {
            captureBackend.toggleRecording(true);
        }
    }

    Component.onCompleted: {
        SystemServices.ensureUserConfigAvailable();
        SystemServices.requestScreenRecordingSnapshot();
        SystemServices.requestVolume();
    }

    Nucleus.ClipboardSource { id: clipboardSource }
    Nucleus.WorkspaceSource { id: workspaceSource }
    Nucleus.NotifySource { id: notifySource }

    Variants {
        id: islandVariants

        model: Quickshell.screens

        Nucleus.NucleusIslandWindow {
            required property var modelData

            screenObject: modelData
            shellRootController: shellRoot
            captureController: captureBackend
            clipboard: clipboardSource
            notifications: notifySource
            workspaces: workspaceSource
        }
    }

    Variants {
        id: barVariants

        model: Quickshell.screens

        Nucleus.NucleusStatusBarWindow {
            required property var modelData

            screenObject: modelData
            shellRootController: shellRoot
        }
    }
}
