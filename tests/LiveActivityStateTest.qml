import QtQuick

// Generated from DynamicIslandWindow.qml — the live-activity resting-state logic
// is pasted in verbatim so the test exercises the shipped code, not a copy.
Item {
    id: islandContainer

    property string islandState: "normal"
    property string restingState: "normal"
    property bool hasCustomLeftItems: false

    property bool mediaLive: false
    property bool timerLive: false
    property bool recordingLive: false
    property int liveActivityOrderCounter: 0
    property int mediaLiveOrder: 0
    property int timerLiveOrder: 0
    property int recordingLiveOrder: 0

    property var log: []

    readonly property QtObject root: QtObject { property bool overviewVisible: false }

    readonly property string activeLiveActivity: {
            let best = "none";
            let bestOrder = 0;
            if (recordingLive && recordingLiveOrder > bestOrder) {
                best = "recording";
                bestOrder = recordingLiveOrder;
            }
            if (timerLive && timerLiveOrder > bestOrder) {
                best = "timer";
                bestOrder = timerLiveOrder;
            }
            if (mediaLive && mediaLiveOrder > bestOrder) {
                best = "media";
                bestOrder = mediaLiveOrder;
            }
            return best;
        }

    function normalizeRestingState(nextState) {
        if (nextState === "lyrics") return "lyrics";
        if (nextState === "custom" && hasCustomLeftItems) return "custom";
        return "normal";
    }

        function liveActivityState() {
            switch (activeLiveActivity) {
            case "recording":
                return "capture_recording";
            case "timer":
                return "live_timer";
            case "media":
                return "live_media";
            default:
                return "";
            }
        }

        // The single source of truth for "what does the island go back to?".
        // Everything transient collapses to this, never to a hardcoded idle.
        function effectiveRestingState() {
            const liveState = liveActivityState();
            if (liveState !== "")
                return liveState;
            return normalizeRestingState(restingState);
        }

        function isRestingLikeState(state) {
            return state === "normal"
                || state === "custom"
                || state === "lyrics"
                || state === "live_media"
                || state === "live_timer"
                || state === "capture_recording";
        }

        // Re-seat the capsule when a live activity starts or ends. If something
        // transient is on top right now we leave it alone: it re-evaluates the
        // resting state when it collapses, so an activity that ended meanwhile
        // correctly falls through to the clock.
        function syncLiveActivityResting() {
            if (root.overviewVisible) return;
            if (!isRestingLikeState(islandState)) return;
            const target = effectiveRestingState();
            if (islandState === target) return;
            restoreRestingCapsule(true);
        }


    // Stand-ins for the window's capsule plumbing.
    function restoreRestingCapsule(forceImmediate) {
        islandState = effectiveRestingState();
    }

    function setMediaLive(value) {
        mediaLive = value;
        mediaLiveOrder = value ? ++liveActivityOrderCounter : 0;
        syncLiveActivityResting();
    }
    function setTimerLive(value) {
        timerLive = value;
        timerLiveOrder = value ? ++liveActivityOrderCounter : 0;
        syncLiveActivityResting();
    }
    // --- Transient alert queueing (from DynamicIslandWindow.qml) -----------
    property var pendingNotifications: []
    property var queuedNotification: null
    property int pulseCount: 0
    property bool mediaPlaying: false
    property string currentTrack: ""

    function pulseCapsule() { pulseCount = pulseCount + 1; }

    function enqueueNotification(entry) {
        const queue = pendingNotifications.slice();
        queue.push(entry);
        if (queue.length > 8)
            queue.splice(0, queue.length - 8);
        pendingNotifications = queue;
    }

    function drainPendingNotification() {
        if (pendingNotifications.length === 0) return false;
        const queue = pendingNotifications.slice();
        queuedNotification = queue.shift();
        pendingNotifications = queue;
        return true;
    }

    function showNotification(summary) {
        if (islandState === "notification" || queuedNotification !== null) {
            enqueueNotification({ summary: summary === undefined ? "" : summary });
            return;
        }
        notificationSummary = summary === undefined ? "" : summary;
        islandState = "notification";
    }
    property string notificationSummary: ""

    // The queue timer's job, minus the delay.
    function presentQueuedNotification() {
        const entry = queuedNotification;
        queuedNotification = null;
        if (!entry) return;
        notificationSummary = entry.summary;
        islandState = "notification";
    }

    function autoHideFired() {
        const wasNotification = islandState === "notification";
        restoreRestingCapsule(true);
        if (wasNotification)
            drainPendingNotification();
    }

    // Ongoing media never expands itself: pause/resume/track change only ever
    // touch content, and only a deliberate long press opens the card.
    function setPlaying(value) {
        mediaPlaying = value;
        setMediaLive(true);
    }

    function changeTrack(title) {
        currentTrack = title;
        if (islandState !== "live_media") return;
        pulseCapsule();
    }

    readonly property bool canExpandRestingActivity:
        islandState === "live_media" || islandState === "live_timer"

    function expandRestingActivity() {
        if (!canExpandRestingActivity) return;
        islandState = "expanded";
    }

    function check(label, actual, expected) {
        const ok = actual === expected;
        console.log((ok ? "PASS  " : "FAIL  ") + label + " => " + actual + (ok ? "" : " (expected " + expected + ")"));
        // Qt.exit does not stop execution, so bail out of the whole run too,
        // otherwise a later Qt.exit(0) would mask the failure exit code.
        if (!ok) {
            Qt.exit(1);
            throw new Error("assertion failed: " + label);
        }
    }

    Component.onCompleted: {
        check("idle at start", islandState, "normal");

        // 1) song starts -> compact now playing, stays there
        setMediaLive(true);
        check("song playing shows compact media", islandState, "live_media");
        check("resting state is media", effectiveRestingState(), "live_media");

        // 2) notification over a live activity -> back to media, not the clock
        showNotification();
        check("notification overlays", islandState, "notification");
        autoHideFired();
        check("notification collapses to media", islandState, "live_media");

        // 3) song stops -> back to idle clock
        setMediaLive(false);
        check("stopped media falls back to clock", islandState, "normal");

        // 4) live activity ends while a notification is on top -> idle
        setMediaLive(true);
        showNotification();
        setMediaLive(false);
        check("ended activity keeps notification", islandState, "notification");
        autoHideFired();
        check("collapses to clock, not dead activity", islandState, "normal");

        // 5) deterministic priority: most recently started wins, stably
        setMediaLive(true);
        setTimerLive(true);
        check("timer started last owns capsule", islandState, "live_timer");
        check("priority stable on re-evaluation", effectiveRestingState(), "live_timer");
        setTimerLive(false);
        check("timer ends -> media resumes", islandState, "live_media");

        // 6) recording outranks nothing implicitly, just recency
        recordingLive = true;
        recordingLiveOrder = ++liveActivityOrderCounter;
        syncLiveActivityResting();
        check("recording takes over", islandState, "capture_recording");
        recordingLive = false;
        recordingLiveOrder = 0;
        syncLiveActivityResting();
        check("recording ends -> media resumes", islandState, "live_media");

        // 7) user-chosen clock variant still honoured when nothing is live
        setMediaLive(false);
        restingState = "lyrics";
        restoreRestingCapsule(true);
        check("lyrics resting honoured", islandState, "lyrics");

        // 8) ongoing media never expands on its own
        restingState = "normal";
        setMediaLive(false);
        restoreRestingCapsule(true);
        setPlaying(true);
        check("play start -> compact, not expanded", islandState, "live_media");
        setPlaying(false);
        check("pause stays compact", islandState, "live_media");
        setPlaying(true);
        check("resume stays compact", islandState, "live_media");

        const pulsesBefore = pulseCount;
        changeTrack("Next Song");
        check("track change stays compact", islandState, "live_media");
        check("track change pulses instead", pulseCount, pulsesBefore + 1);

        // 9) only a deliberate long press / tap opens the full card
        expandRestingActivity();
        check("long press expands", islandState, "expanded");
        restoreRestingCapsule(true);
        check("collapse returns to playing media", islandState, "live_media");

        // 10) a second alert queues instead of overlapping
        showNotification("first");
        check("first alert shows", notificationSummary, "first");
        showNotification("second");
        check("second alert queued, not shown", notificationSummary, "first");
        check("queue holds one", pendingNotifications.length, 1);
        autoHideFired();
        check("collapses to media between alerts", islandState, "live_media");
        presentQueuedNotification();
        check("queued alert shown next", notificationSummary, "second");
        check("queue drained", pendingNotifications.length, 0);
        autoHideFired();
        check("final collapse back to media", islandState, "live_media");
        setMediaLive(false);
        check("media ends -> idle", islandState, "normal");

        console.log("ALL PASS");
        Qt.exit(0);
    }
}
