pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import IslandBackend

// Wallpaper library for the island picker (SUPER + W).
//
// The library folder, target copy, transition and pywal behaviour all come from
// the same user config keys the settings app writes, so the island picker and
// the settings page always agree. Applying tries awww first (the shipped
// default), then swww, hyprpaper and swaybg, so a missing tool no longer makes
// clicking a wallpaper look like it does nothing.
Item {
    id: root

    readonly property var userConfig: UserConfig

    // [{ name, path }]
    property var entries: []
    property string appliedPath: ""
    property string lastError: ""
    readonly property int count: root.entries.length

    signal applied(string path)
    signal failed(string message)

    visible: false
    width: 0
    height: 0

    readonly property string libraryPath: {
        const configured = String(root.userConfig.wallpaperLibraryPath || "").trim();
        return configured === "" ? "~/Pictures/Wallpapers" : configured;
    }

    Component.onCompleted: root.refresh()
    onLibraryPathChanged: root.refresh()

    function quoted(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function refresh() {
        scan.command = ["sh", "-c", root.scanScript()];
        scan.running = false;
        scan.running = true;
    }

    function scanScript() {
        return [
            "dir=" + root.quoted(root.libraryPath),
            "case \"$dir\" in \"~\"*) dir=\"$HOME${dir#?}\";; esac",
            "find \"$dir\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg'"
                + " -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp'"
                + " -o -iname '*.avif' -o -iname '*.jxl' -o -iname '*.gif' \\)"
                + " 2>/dev/null | sort"
        ].join("; ");
    }

    function applyScript(path) {
        const custom = String(root.userConfig.wallpaperCustomCommand || "").trim();
        const useCustom = !!root.userConfig.wallpaperCustomCommandEnabled && custom !== "";
        const target = String(root.userConfig.wallpaperPath || "").trim();
        const transition = String(root.userConfig.wallpaperTransitionType || "").trim() || "center";
        const duration = String(Math.max(0, Number(root.userConfig.wallpaperTransitionDuration) || 3));
        const fps = String(Math.max(1, Number(root.userConfig.wallpaperTransitionFps) || 60));

        const lines = ["set -e", "src=" + root.quoted(path)];

        if (useCustom) {
            lines.push("sh -c " + root.quoted(custom) + " tide-island-wallpaper \"$src\"");
            return lines.join("\n");
        }

        if (target !== "") {
            lines.push("target=" + root.quoted(target));
            lines.push("case \"$target\" in \"~\"*) target=\"$HOME${target#?}\";; esac");
            lines.push("mkdir -p \"$(dirname \"$target\")\"");
            lines.push("[ \"$src\" = \"$target\" ] || cp -f \"$src\" \"$target\"");
            lines.push("applied=\"$target\"");
        } else {
            lines.push("applied=\"$src\"");
        }

        lines.push([
            "if command -v awww >/dev/null 2>&1; then",
            "  awww img \"$applied\" --transition-type " + transition
                + " --transition-duration " + duration + " --transition-fps " + fps + ";",
            "elif command -v swww >/dev/null 2>&1; then",
            "  swww img \"$applied\" --transition-type " + transition
                + " --transition-duration " + duration + " --transition-fps " + fps + ";",
            "elif command -v hyprctl >/dev/null 2>&1 && pgrep -x hyprpaper >/dev/null 2>&1; then",
            "  hyprctl hyprpaper preload \"$applied\" >/dev/null;",
            "  hyprctl hyprpaper wallpaper \",$applied\" >/dev/null;",
            "elif command -v swaybg >/dev/null 2>&1; then",
            "  pkill -x swaybg >/dev/null 2>&1 || true;",
            "  setsid swaybg -i \"$applied\" -m fill >/dev/null 2>&1 &",
            "else",
            "  echo 'No wallpaper tool found (awww, swww, hyprpaper or swaybg).' >&2;",
            "  exit 1;",
            "fi"
        ].join("\n"));

        if (root.userConfig.wallpaperPywalEnabled)
            lines.push("command -v wal >/dev/null 2>&1 && wal -n -q -i \"$src\" || true");

        return lines.join("\n");
    }

    function apply(path) {
        const target = String(path || "").trim();
        if (target === "")
            return;
        root.appliedPath = target;
        root.lastError = "";
        applyProcess.command = ["sh", "-c", root.applyScript(target)];
        applyProcess.running = false;
        applyProcess.running = true;
    }

    Process {
        id: scan

        stdout: StdioCollector {
            onStreamFinished: {
                const built = [];
                const lines = String(this.text).split("\n");
                for (let index = 0; index < lines.length; ++index) {
                    const path = lines[index].trim();
                    if (path === "")
                        continue;
                    const slash = path.lastIndexOf("/");
                    built.push({
                        name: slash === -1 ? path : path.slice(slash + 1),
                        path: path
                    });
                }
                root.entries = built;
            }
        }
    }

    Process {
        id: applyProcess

        stderr: StdioCollector {
            onStreamFinished: {
                root.lastError = String(this.text).trim();
            }
        }

        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.applied(root.appliedPath);
            } else {
                root.failed(root.lastError === ""
                    ? "The wallpaper command failed."
                    : root.lastError);
            }
        }
    }
}
