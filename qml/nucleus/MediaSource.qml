pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris

// Minimal MPRIS bridge for the island. Only what the reference media layouts
// need: title, artist, artwork, playing flag, position and transport calls.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var player: null
    property real position: 0
    property real length: 0

    readonly property var players: Mpris.players && Mpris.players.values !== undefined
        ? Mpris.players.values
        : []

    readonly property bool playing: root.player
        ? root.player.playbackState === MprisPlaybackState.Playing
        : false
    readonly property bool paused: root.player
        ? root.player.playbackState === MprisPlaybackState.Paused
        : false
    readonly property bool live: (root.playing || root.paused) && root.title !== ""

    readonly property string title: root.player
        ? String(root.player.trackTitle || root.player.title || "")
        : ""
    readonly property string artist: {
        if (!root.player)
            return "";
        const value = root.player.trackArtist !== undefined
            ? root.player.trackArtist
            : root.player.artist;
        if (!value)
            return "";
        return Array.isArray(value) ? value.join(", ") : String(value);
    }
    readonly property string artUrl: root.player
        ? String(root.player.trackArtUrl || root.player.artUrl || "")
        : ""

    readonly property real progress: root.length > 0
        ? Math.max(0, Math.min(1, root.position / root.length))
        : 0
    readonly property string elapsedText: root.formatClock(root.position)
    readonly property string remainingText: root.formatClock(Math.max(0, root.length - root.position))

    onPlayersChanged: root.pick()
    Component.onCompleted: root.pick()

    function pick() {
        const list = root.players;
        let fallback = null;
        for (let index = 0; index < list.length; index++) {
            const candidate = list[index];
            if (!candidate)
                continue;
            if (!fallback)
                fallback = candidate;
            if (candidate.playbackState === MprisPlaybackState.Playing) {
                root.player = candidate;
                return;
            }
        }
        root.player = fallback;
    }

    function formatClock(seconds) {
        const safe = Math.max(0, Math.round(seconds));
        const minutes = Math.floor(safe / 60);
        const rest = safe % 60;
        return minutes + ":" + (rest < 10 ? "0" + rest : "" + rest);
    }

    function togglePlaying() {
        if (!root.player)
            return;
        if (root.player.togglePlaying)
            root.player.togglePlaying();
    }

    function next() {
        if (root.player && root.player.next)
            root.player.next();
    }

    function previous() {
        if (root.player && root.player.previous)
            root.player.previous();
    }

    Timer {
        interval: 500
        running: root.player !== null
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            const player = root.player;
            if (!player)
                return;
            if (player.positionSupported !== false && player.positionChanged)
                player.positionChanged();
            root.position = player.position !== undefined ? Number(player.position) : 0;
            root.length = player.length !== undefined ? Number(player.length) : 0;
        }
    }
}
