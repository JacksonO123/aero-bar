pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Picks the "current" MPRIS player and exposes its track in a null-safe way.
// Preference order: a player the user switched to (until another one starts playing), whatever
// is playing, whatever played last, anything with a title, anything at all.
Singleton {
    id: root

    readonly property var players: Mpris.players.values

    property MprisPlayer pinned: null
    property MprisPlayer lastActive: null

    // a player that starts playing takes over from the pinned one
    readonly property var playing: players.filter(p => p.isPlaying)
    property var wasPlaying: []

    onPlayingChanged: {
        if (pinned && playing.some(p => p !== pinned && !wasPlaying.includes(p))) {
            pinned = null;
        }
        wasPlaying = playing;
    }

    readonly property MprisPlayer player: {
        const list = players;

        if (pinned && list.includes(pinned)) {
            return pinned;
        }

        for (const p of list) {
            if (p.isPlaying) {
                return p;
            }
        }

        if (lastActive && list.includes(lastActive)) {
            return lastActive;
        }

        for (const p of list) {
            if (p.trackTitle) {
                return p;
            }
        }

        return list.length > 0 ? list[0] : null;
    }

    readonly property bool hasPlayer: player !== null
    readonly property string title: player ? (player.trackTitle || "Unknown Title") : ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property string identity: player?.identity ?? ""
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property bool canToggle: player?.canTogglePlaying ?? false
    readonly property bool canNext: player?.canGoNext ?? false
    readonly property bool canPrevious: player?.canGoPrevious ?? false
    readonly property bool canSeek: (player?.canSeek ?? false) && (player?.positionSupported ?? false)
    readonly property real length: (player?.lengthSupported ?? false) ? player.length : 0

    onPlayerChanged: {
        if (player && player.isPlaying) {
            lastActive = player;
        }
    }

    Connections {
        target: root.player

        function onIsPlayingChanged() {
            if (root.player.isPlaying) {
                root.lastActive = root.player;
            }
        }
    }

    function togglePlaying() {
        if (canToggle) {
            player.togglePlaying();
        }
    }

    function next() {
        if (canNext) {
            player.next();
        }
    }

    function previous() {
        if (canPrevious) {
            player.previous();
        }
    }

    function raise() {
        if (player?.canRaise) {
            player.raise();
        }
    }

    function seek(seconds) {
        if (canSeek) {
            player.position = Math.max(0, Math.min(length, seconds));
        }
    }

    function cycle() {
        const list = players;
        if (list.length < 2) {
            return;
        }

        const index = list.indexOf(player);
        pinned = list[(index + 1) % list.length];
    }
}
