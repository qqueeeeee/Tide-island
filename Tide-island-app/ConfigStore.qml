pragma Singleton
import QtQuick

// Single source of truth for the user config. Every control writes through
// here, changes apply live (debounced write to the JSON the shell watches).
QtObject {
    id: store

    readonly property string path: backend.userConfigPath
    readonly property string errorString: backend.errorString

    property var map: backend.userConfig
    // Bumped on every write so bindings re-evaluate.
    property int revision: 0
    property string status: ""

    readonly property var defaults: ({
        // Island geometry
        "islandTopMargin": 11,
        "islandScale": 100,
        "islandCornerRadius": 32,
        "islandBottomGap": 8,
        "islandReserveSpace": true,
        "islandBackgroundOpacity": 100,
        // Status bar
        "statusBarEnabled": true,
        "statusBarSideMargin": 22,
        "statusBarIslandGap": 14,
        "statusBarItemSpacing": 14,
        "statusBarBaselineOffset": 0,
        "statusBarOpacity": 100,
        "statusBarShowWorkspaces": true,
        "statusBarShowActiveWindow": true,
        "statusBarShowStatusIcons": true,
        "statusBarShowClock": true,
        "statusBarShowDateOnHover": true,
        "statusBarFadeWithIsland": true,
        // Appearance
        "textFontFamily": "Inter Display",
        "heroFontFamily": "Inter Display",
        "timeFontFamily": "Inter Display",
        "iconFontFamily": "JetBrainsMono Nerd Font",
        "bodyFontSize": 16,
        "titleFontSize": 20,
        "iconFontSize": 18,
        "clockFormat": "12",
        // Capture
        "captureVideoDirectory": "",
        "captureScreenshotDirectory": "",
        "captureAnnotationTool": "",
        "captureRecordAudio": true,
        "captureCopyToClipboard": true,
        "captureNotify": true,
        "captureShowScreenshotPreview": true,
        "captureScreenshotPreviewSeconds": 6
    })

    property Timer writeTimer: Timer {
        interval: 220
        onTriggered: store.flush()
    }

    function value(key) {
        // Reading `revision` makes every binding that calls value() reactive.
        const tracked = store.revision;
        const current = store.map[key];
        if (current === undefined || current === null)
            return store.defaults[key];
        return current;
    }

    function number(key) {
        return Number(store.value(key));
    }

    function flag(key) {
        return store.value(key) === true;
    }

    function text(key) {
        const current = store.value(key);
        return current === undefined ? "" : String(current);
    }

    function set(key, newValue) {
        const current = store.map[key];
        if (current === newValue)
            return;
        store.map[key] = newValue;
        store.revision++;
        store.writeTimer.restart();
    }

    function reset(key) {
        store.set(key, store.defaults[key]);
    }

    function resetKeys(keys) {
        for (let index = 0; index < keys.length; index++)
            store.map[keys[index]] = store.defaults[keys[index]];
        store.revision++;
        store.writeTimer.restart();
    }

    function flush() {
        if (backend.save(store.map)) {
            store.status = "Saved to " + store.path;
        } else {
            store.status = backend.errorString;
        }
    }
}
