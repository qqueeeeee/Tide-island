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

    function screensForMode(mode, name) {
        const all = Quickshell.screens;
        if (mode === "primary") {
            for (let i = 0; i < all.length; i++) {
                if (all[i] && all[i].primary)
                    return [all[i]];
            }
            return all.length > 0 ? [all[0]] : [];
        }
        if (mode === "named") {
            const wanted = String(name === undefined || name === null ? "" : name).trim();
            if (wanted === "")
                return all;
            const filtered = all.filter((screen) => screen && screen.name === wanted);
            return filtered.length > 0 ? filtered : all;
        }
        return all;
    }

    readonly property var islandScreens: shellRoot.screensForMode(
        userConfig.islandMonitorMode, userConfig.islandMonitorName)
    readonly property var statusBarScreens: shellRoot.screensForMode(
        userConfig.statusBarMonitorMode, userConfig.statusBarMonitorName)

    CaptureController {
        id: captureBackend
    }

    // Launches the Tide Island settings app. Declared at shell scope so the
    // "settings" IPC target (SUPER + ,) can reach it; the Control Centre gear
    // owns its own copy of this process.
    Process {
        id: settingsApp

        command: ["sh", "-c", "true"]
    }

    // page: "" | "island" | "wallpaper" | "shortcuts" | ...
    function launchSettings(page) {
        const requested = page === undefined || page === null ? "" : String(page).trim();
        const arg = requested === "" ? "" : " --page " + requested;
        const script = "pgrep -x tide-island-config-app >/dev/null 2>&1 && exit 0; "
            + "tide-island-config-app" + arg + " >/dev/null 2>&1 "
            + "|| /usr/bin/tide-island-config-app" + arg + " >/dev/null 2>&1";
        if (settingsApp.running)
            settingsApp.running = false;
        settingsApp.command = ["sh", "-c", script];
        settingsApp.running = true;
    }

    // --- Duplicate-bind guard ----------------------------------------------
    // Users very often bind these commands in their own compositor config while
    // an older Tide Island managed bind is still installed, so one key press
    // arrives twice and a toggle cancels itself out (the launcher flashing open
    // then shut). Collapsing repeats of the same command inside one press
    // window makes double binds harmless.
    property var lastCallStamps: ({})

    function accept(key) {
        const now = Date.now();
        const previous = shellRoot.lastCallStamps[key] || 0;
        if (now - previous < 280)
            return false;
        shellRoot.lastCallStamps[key] = now;
        return true;
    }

    function once(key, callback) {
        if (!shellRoot.accept(key))
            return;
        shellRoot.forEachIsland(callback);
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
            shellRoot.once("controlCenter", (island) => island.toggleControlCentre());
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
            shellRoot.once("launcher", (island) => island.toggleLauncher());
        }

        function clipboard() {
            shellRoot.once("clipboard", (island) => island.toggleClipboard());
        }

        function notifications() {
            shellRoot.once("notifications", (island) => island.toggleNotifications());
        }

        function workspaces() {
            shellRoot.once("workspaces", (island) => island.toggleWorkspaces());
        }

        function close() {
            shellRoot.forEachIsland((island) => island.closePanel());
        }

        // Legacy SUPER+F binding: reveal the Control Centre, or dismiss
        // whatever panel is currently open.
        function toggle() {
            shellRoot.once("controlCenter", (island) => island.toggleControlCentre());
        }
    }


    // Compatibility target: shortcut names shipped by older Tide Island
    // configs still work, mapped onto the nucleus panels.
    IpcHandler {
        target: "tide"

        function toggleControlCenter() {
            shellRoot.once("controlCenter", (island) => island.toggleControlCentre());
        }

        function toggleNotificationCenter() {
            shellRoot.once("notifications", (island) => island.toggleNotifications());
        }

        function toggleApplicationLauncher() {
            shellRoot.once("launcher", (island) => island.toggleLauncher());
        }

        // Media, not the Control Centre: expands the Now Playing card when
        // something is playing, and says so when nothing is.
        function togglePlayer() {
            shellRoot.once("player", (island) => island.togglePlayer());
        }

        // The iOS clock peek: time and date on the capsule for a moment.
        function showClock() {
            shellRoot.once("clock", (island) => island.showClockPeek());
        }

        function swipeRight() {
            shellRoot.once("workspaces", (island) => island.toggleWorkspaces());
        }

        function swipeLeft() {
            shellRoot.once("clipboard", (island) => island.toggleClipboard());
        }

        // SUPER + W: the island's own wallpaper picker panel.
        function toggleWallpaperPicker() {
            shellRoot.once("wallpaper", (island) => island.toggleWallpaperPicker());
        }
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            shellRoot.once("workspaces", (island) => island.toggleWorkspaces());
        }
    }

    IpcHandler {
        target: "settings"

        function open() {
            if (shellRoot.accept("settings"))
                shellRoot.launchSettings("");
        }

        function toggle() {
            if (shellRoot.accept("settings"))
                shellRoot.launchSettings("");
        }

        function wallpaper() {
            shellRoot.once("wallpaper", (island) => island.toggleWallpaperPicker());
        }
    }


    IpcHandler {
        target: "capture"

        function screenshot() {
            captureBackend.takeScreenshot("area");
        }

        function screenshotArea() {
            if (shellRoot.accept("screenshotArea"))
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
            if (shellRoot.accept("toggleRecording"))
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

    Nucleus.HudSource {
        id: hudSource

        onVolumeChanged: (value, muted) => {
            shellRoot.forEachIsland((island) => island.showVolume(value, muted));
        }

        onBrightnessChanged: (value) => {
            shellRoot.forEachIsland((island) => island.showBrightness(value));
        }
    }

    Nucleus.ClipboardSource { id: clipboardSource }
    Nucleus.WorkspaceSource { id: workspaceSource }
    Nucleus.NotifySource { id: notifySource }
    Nucleus.WallpaperSource {
        id: wallpaperSource

        onFailed: (message) => {
            shellRoot.forEachIsland((island) => island.showNotification("Wallpaper", "Could not apply wallpaper", message));
        }
    }

    Variants {
        id: islandVariants

        model: shellRoot.islandScreens

        Nucleus.NucleusIslandWindow {
            required property var modelData

            screenObject: modelData
            shellRootController: shellRoot
            captureController: captureBackend
            clipboard: clipboardSource
            notifications: notifySource
            workspaces: workspaceSource
            wallpapers: wallpaperSource
        }
    }

    Variants {
        id: barVariants

        model: shellRoot.statusBarScreens

        Nucleus.NucleusStatusBarWindow {
            required property var modelData

            screenObject: modelData
            shellRootController: shellRoot
        }
    }
}
