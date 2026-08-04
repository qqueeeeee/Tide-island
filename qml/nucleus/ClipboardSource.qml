pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import IslandBackend

// Clipboard history bridge on top of `cliphist` (the standard Hyprland clipboard
// daemon). It keeps the parsed entries as a plain JS array so the layer can
// filter it exactly like the React reference does.
//
// An entry is: { id, kind: "text"|"image"|"link", value, meta }
Item {
    id: root

    readonly property var userConfig: UserConfig

    property var entries: []
    readonly property int count: root.entries.length
    property bool available: true

    readonly property int historyLimit: Math.max(5, Math.min(500, userConfig.clipboardHistoryLimit))
    readonly property bool showImagePreviews: userConfig.clipboardShowImagePreviews
    readonly property var excludedApps: {
        const list = userConfig.clipboardExcludedApps || [];
        const out = [];
        for (let i = 0; i < list.length; i++)
            out.push(String(list[i]).toLowerCase());
        return out;
    }

    function isAppExcluded(meta) {
        const value = String(meta === undefined || meta === null ? "" : meta).toLowerCase();
        if (value === "" || root.excludedApps.length === 0)
            return false;
        for (let i = 0; i < root.excludedApps.length; i++) {
            if (value.indexOf(root.excludedApps[i]) !== -1)
                return true;
        }
        return false;
    }

    visible: false
    width: 0
    height: 0

    function parseLine(line) {
        const raw = String(line === undefined || line === null ? "" : line);
        if (raw.trim() === "")
            return null;

        const tab = raw.indexOf("\t");
        if (tab <= 0)
            return null;

        const id = raw.slice(0, tab).trim();
        const body = raw.slice(tab + 1);
        const trimmed = body.trim();
        if (id === "" || trimmed === "")
            return null;

        // cliphist renders binary payloads as "[[ binary data 42 KiB png 1512x982 ]]".
        const binary = trimmed.match(/^\[\[\s*binary data\s+(.+?)\s*\]\]$/i);
        if (binary) {
            const details = String(binary[1]).split(/\s+/);
            return {
                id: id,
                kind: "image",
                value: details.length > 2 ? details.slice(1).join(" ") : trimmed,
                meta: details.join(" · ")
            };
        }

        const isLink = /^(https?:\/\/|www\.)\S+$/i.test(trimmed);
        return {
            id: id,
            kind: isLink ? "link" : "text",
            value: trimmed,
            meta: isLink
                ? trimmed.replace(/^https?:\/\//i, "").split("/")[0]
                : trimmed.length + " characters"
        };
    }

    function refresh() {
        listProcess.running = false;
        listProcess.buffer = "";
        listProcess.running = true;
    }

    function paste(entry) {
        if (!entry)
            return;
        // Put the entry back on the clipboard; the compositor paste shortcut then
        // works exactly as if it had just been copied.
        decodeProcess.command = ["sh", "-c",
            "cliphist decode " + root.shellQuote(entry.id) + " | wl-copy"];
        decodeProcess.running = true;
    }

    function remove(entry) {
        if (!entry)
            return;
        deleteProcess.command = ["sh", "-c",
            "cliphist decode " + root.shellQuote(entry.id) + " | cliphist delete"];
        deleteProcess.running = true;
        root.entries = root.entries.filter((item) => item.id !== entry.id);
    }

    function wipe() {
        wipeProcess.running = true;
        root.entries = [];
    }

    function shellQuote(value) {
        return "'" + String(value === undefined || value === null ? "" : value)
            .replace(/'/g, "'\\''") + "'";
    }

    Process {
        id: listProcess

        property string buffer: ""

        command: ["cliphist", "list"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                listProcess.buffer += line + "\n";
            }
        }

        onExited: (exitCode) => {
            root.available = exitCode === 0;
            if (exitCode !== 0) {
                console.log("[ClipboardSource] cliphist unavailable (exit " + exitCode + ")");
                return;
            }

            const parsed = [];
            const lines = listProcess.buffer.split("\n");
            for (let index = 0; index < lines.length && parsed.length < root.historyLimit; index++) {
                const entry = root.parseLine(lines[index]);
                if (!entry)
                    continue;
                if (entry.kind === "image" && !root.showImagePreviews)
                    continue;
                if (root.isAppExcluded(entry.meta))
                    continue;
                parsed.push(entry);
            }
            root.entries = parsed;
        }
    }

    Process { id: decodeProcess }
    Process { id: deleteProcess }
    Process { id: wipeProcess; command: ["sh", "-c", "cliphist wipe"] }
}
