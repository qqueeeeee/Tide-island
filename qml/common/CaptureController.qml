pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import IslandBackend

// Screen capture controller. The process handling is lifted from the old
// hyprmoon quickshell config (wf-recorder started through `sh -c ... exec` so a
// SIGINT reaches the recorder directly, plus a post-process that only touches
// the clipboard when the file exists and is non-empty). Screenshots reuse the
// grim + slurp pair the hyprmoon keybinds used through grimblast.
Item {
    id: root

    readonly property var userConfig: UserConfig

    // --- Recording state ---
    property bool recording: false
    property bool recordingPaused: false
    property int recordingSeconds: 0
    property string recordingPath: ""
    readonly property bool recordingRegion: pendingRegion
    property bool pendingRegion: false
    readonly property string elapsedText: root.formatDuration(root.recordingSeconds)

    // --- Screenshot state ---
    property string lastScreenshotPath: ""
    property bool screenshotPending: false

    property string lastError: ""

    signal recordingStarted()
    signal recordingFinished(string path)
    signal screenshotCaptured(string path)
    signal screenshotDismissed()

    visible: false

    // ---------------------------------------------------------------- helpers
    function pad2(value) {
        return value < 10 ? "0" + value : "" + value;
    }

    function formatDuration(totalSeconds) {
        const total = Math.max(0, Math.floor(totalSeconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;
        return hours > 0
            ? hours + ":" + root.pad2(minutes) + ":" + root.pad2(seconds)
            : root.pad2(minutes) + ":" + root.pad2(seconds);
    }

    function timestamp() {
        const now = new Date();
        return now.getFullYear()
            + "-" + root.pad2(now.getMonth() + 1)
            + "-" + root.pad2(now.getDate())
            + "_" + root.pad2(now.getHours())
            + "." + root.pad2(now.getMinutes())
            + "." + root.pad2(now.getSeconds());
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function homeDirectory() {
        const home = Quickshell.env("HOME");
        return home && String(home) !== "" ? String(home) : "/tmp";
    }

    function resolveDirectory(configured, fallbackSuffix) {
        const raw = configured === undefined || configured === null ? "" : String(configured).trim();
        if (raw === "")
            return root.homeDirectory() + fallbackSuffix;
        if (raw.charAt(0) === "~")
            return root.homeDirectory() + raw.substring(1);
        return raw;
    }

    readonly property string videoDirectory: root.resolveDirectory(
        userConfig.captureVideoDirectory, "/Videos"
    )
    readonly property string screenshotDirectory: root.resolveDirectory(
        userConfig.captureScreenshotDirectory, "/Pictures/Screenshots"
    )

    function fileName(path) {
        const value = String(path);
        const index = value.lastIndexOf("/");
        return index >= 0 ? value.substring(index + 1) : value;
    }

    function notifyCommand(title, path) {
        return root.userConfig.captureNotify
            ? "notify-send " + root.shellQuote(title) + " " + root.shellQuote(path) + "; "
            : "";
    }

    // -------------------------------------------------------------- recording
    function toggleRecording(region) {
        if (root.recording)
            root.stopRecording();
        else
            root.startRecording(region);
    }

    function startRecording(region) {
        if (root.recording)
            return;

        const useRegion = region === true;
        const directory = root.videoDirectory;
        const path = directory + "/recording_" + root.timestamp() + ".mp4";
        const audio = root.userConfig.captureRecordAudio
            ? " --audio=$(pactl get-default-sink).monitor"
            : "";
        const prefix = "mkdir -p " + root.shellQuote(directory) + "; ";
        // exec on the wf-recorder line so the SIGINT we send later reaches it
        // directly instead of being trapped by the sh wrapper.
        const recorder = "exec wf-recorder" + audio
            + (useRegion ? " -g \"$g\"" : "")
            + " -f " + root.shellQuote(path);

        root.recordingPath = path;
        root.pendingRegion = useRegion;
        recorderProcess.command = useRegion
            ? ["sh", "-c", prefix + "g=$(slurp) || exit 1; " + recorder]
            : ["sh", "-c", prefix + recorder];
        recorderProcess.running = true;
        root.recording = true;
        root.recordingPaused = false;
        root.recordingSeconds = 0;
        recordingTimer.restart();
        root.recordingStarted();
    }

    function togglePauseRecording() {
        if (!root.recording)
            return;

        // wf-recorder toggles pause/resume on SIGUSR1.
        recorderProcess.signal(10);
        root.recordingPaused = !root.recordingPaused;
    }

    function stopRecording() {
        if (!root.recording)
            return;

        // SIGINT — wf-recorder flushes the container trailer and exits cleanly.
        recorderProcess.signal(2);
    }

    Timer {
        id: recordingTimer

        interval: 1000
        repeat: true
        running: root.recording && !root.recordingPaused
        onTriggered: root.recordingSeconds += 1
    }

    Process {
        id: recorderProcess

        onExited: function(exitCode, exitStatus) {
            const path = root.recordingPath;
            root.recording = false;
            root.recordingPaused = false;
            root.recordingPath = "";
            recordingTimer.stop();

            if (path === "") {
                root.recordingFinished("");
                return;
            }

            // -s covers both the clean SIGINT stop and the slurp-cancelled case.
            const quoted = root.shellQuote(path);
            const copy = root.userConfig.captureCopyToClipboard
                ? "printf 'file://%s\\n' " + quoted + " | wl-copy --type text/uri-list; "
                : "";
            postProcess.command = ["sh", "-c",
                "if [ -s " + quoted + " ]; then " + copy + root.notifyCommand("Recording saved", path) + "fi"];
            postProcess.running = true;
            root.recordingFinished(path);
        }
    }

    Process { id: postProcess }

    // ------------------------------------------------------------ screenshots
    // mode: "area" (slurp selection), "screen" (whole output), "window"
    function takeScreenshot(mode) {
        if (root.screenshotPending)
            return;

        const requested = mode === undefined || mode === null ? "area" : String(mode);
        const directory = root.screenshotDirectory;
        const path = directory + "/screenshot_" + root.timestamp() + ".png";
        const quoted = root.shellQuote(path);
        const prefix = "mkdir -p " + root.shellQuote(directory) + "; ";
        const copy = root.userConfig.captureCopyToClipboard
            ? "wl-copy --type image/png < " + quoted + "; "
            : "";

        let grab;
        // grimblast (hyprmoon's old keybinds used it) handles region selection and
        // saving in one shot; grim + slurp is the fallback when it is absent.
        if (requested === "screen") {
            grab = "if command -v grimblast >/dev/null 2>&1; then grimblast save screen " + quoted
                + "; else grim " + quoted + "; fi";
        } else if (requested === "window") {
            grab = "if command -v grimblast >/dev/null 2>&1; then grimblast save active " + quoted
                + "; else g=$(slurp -r) || exit 1; grim -g \"$g\" " + quoted + "; fi";
        } else {
            grab = "if command -v grimblast >/dev/null 2>&1; then grimblast save area " + quoted
                + "; else g=$(slurp) || exit 1; grim -g \"$g\" " + quoted + "; fi";
        }

        // Fail loudly: without this a missing grim/slurp/wl-clipboard binary looks
        // like the shortcut silently doing nothing.
        const requireTools = "for t in grim slurp; do "
            + "command -v grimblast >/dev/null 2>&1 && break; "
            + "command -v $t >/dev/null 2>&1 || { echo \"missing $t\" >&2; exit 1; }; done; ";

        screenshotProcess.pendingPath = path;
        root.lastError = "";
        root.screenshotPending = true;
        screenshotProcess.command = ["sh", "-c",
            requireTools + prefix + grab
            + " || exit 1; [ -s " + quoted + " ] || exit 1; "
            + copy + root.notifyCommand("Screenshot saved", path) + "exit 0"];
        screenshotProcess.running = true;
    }

    Process {
        id: screenshotProcess

        property string pendingPath: ""

        stderr: StdioCollector {
            id: screenshotErrors

            onStreamFinished: {
                const message = String(screenshotErrors.text).trim();
                if (message !== "")
                    root.lastError = message;
            }
        }

        onExited: function(exitCode, exitStatus) {
            const path = screenshotProcess.pendingPath;
            screenshotProcess.pendingPath = "";
            root.screenshotPending = false;

            if (exitCode !== 0 || path === "") {
                // Exit code 1 with no stderr is the normal "slurp cancelled" case.
                if (root.lastError !== "") {
                    errorProcess.command = ["sh", "-c",
                        "notify-send 'Screenshot failed' " + root.shellQuote(root.lastError)];
                    errorProcess.running = true;
                    root.lastError = "";
                }
                return;
            }

            root.lastScreenshotPath = path;
            root.screenshotCaptured(path);
        }
    }

    function copyLastScreenshot() {
        if (root.lastScreenshotPath === "")
            return;

        actionProcess.command = ["sh", "-c",
            "wl-copy --type image/png < " + root.shellQuote(root.lastScreenshotPath)];
        actionProcess.running = true;
    }

    function annotateLastScreenshot() {
        if (root.lastScreenshotPath === "")
            return;

        const quoted = root.shellQuote(root.lastScreenshotPath);
        const configured = String(root.userConfig.captureAnnotationTool || "").trim();
        // %f is substituted with the screenshot path; otherwise the path is appended.
        let command;
        if (configured !== "") {
            command = configured.indexOf("%f") >= 0
                ? configured.replace(/%f/g, quoted)
                : configured + " " + quoted;
        } else {
            command = "if command -v satty >/dev/null 2>&1; then satty --filename " + quoted
                + "; elif command -v swappy >/dev/null 2>&1; then swappy -f " + quoted
                + "; else xdg-open " + quoted + "; fi";
        }

        actionProcess.command = ["sh", "-c", command];
        actionProcess.running = true;
    }

    function openLastScreenshot() {
        if (root.lastScreenshotPath === "")
            return;

        actionProcess.command = ["sh", "-c",
            "xdg-open " + root.shellQuote(root.lastScreenshotPath) + " >/dev/null 2>&1"];
        actionProcess.running = true;
    }

    function deleteLastScreenshot() {
        if (root.lastScreenshotPath === "")
            return;

        actionProcess.command = ["sh", "-c", "rm -f " + root.shellQuote(root.lastScreenshotPath)];
        actionProcess.running = true;
        root.lastScreenshotPath = "";
        root.screenshotDismissed();
    }

    function dismissScreenshot() {
        root.screenshotDismissed();
    }

    Process { id: actionProcess }

    Process { id: errorProcess }
}
