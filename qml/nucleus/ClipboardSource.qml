pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Clipboard history bridge on top of `cliphist` (the standard Hyprland clipboard
// daemon). It keeps the parsed entries as a plain JS array so the layer can
// filter it exactly like the React reference does.
//
// An entry is: { id, kind: "text"|"image"|"link", value, meta }
Item {
    id: root

    property var entries: []
    readonly property int count: root.entries.length
    property bool available: true

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
            for (let index = 0; index < lines.length && parsed.length < 60; index++) {
                const entry = root.parseLine(lines[index]);
                if (entry)
                    parsed.push(entry);
            }
            root.entries = parsed;
        }
    }

    Process { id: decodeProcess }
    Process { id: deleteProcess }
    Process { id: wipeProcess; command: ["sh", "-c", "cliphist wipe"] }
}
