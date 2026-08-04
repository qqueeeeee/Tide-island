pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import IslandBackend

// Minimal MPRIS bridge for the island. Only what the reference media layouts
// need: title, artist, artwork, playing flag, position and transport calls.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    readonly property var userConfig: UserConfig

    property var player: null
    property real position: 0
    property real length: 0

    function normalizedList(raw) {
        const list = raw || [];
        const out = [];
        for (let i = 0; i < list.length; i++)
            out.push(String(list[i]).toLowerCase());
        return out;
    }

    readonly property var excludedPlayers: root.normalizedList(userConfig.mediaExcludedPlayers)
    readonly property var preferredPlayers: root.normalizedList(userConfig.mediaPreferredPlayers)

    function playerIdentity(candidate) {
        if (!candidate)
            return "";
        const identity = candidate.identity !== undefined ? candidate.identity : "";
        const service = candidate.dbusName !== undefined ? candidate.dbusName : "";
        return String(identity || service || "").toLowerCase();
    }

    function isExcluded(candidate) {
        const identity = root.playerIdentity(candidate);
        if (identity === "")
            return false;
        for (let i = 0; i < root.excludedPlayers.length; i++) {
            if (identity.indexOf(root.excludedPlayers[i]) !== -1)
                return true;
        }
        return false;
    }

    function preferenceRank(candidate) {
        const identity = root.playerIdentity(candidate);
        for (let i = 0; i < root.preferredPlayers.length; i++) {
            if (identity.indexOf(root.preferredPlayers[i]) !== -1)
                return i;
        }
        return root.preferredPlayers.length;
    }

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
        const list = root.players.filter((candidate) => candidate && !root.isExcluded(candidate));

        const playing = list.filter((candidate) => candidate.playbackState === MprisPlaybackState.Playing);
        if (playing.length > 0) {
            playing.sort((a, b) => root.preferenceRank(a) - root.preferenceRank(b));
            root.player = playing[0];
            return;
        }

        if (list.length === 0) {
            root.player = null;
            return;
        }

        const sorted = list.slice().sort((a, b) => root.preferenceRank(a) - root.preferenceRank(b));
        root.player = sorted[0];
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
