pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var players: Mpris.players.values

    property MprisPlayer pinned: null
    property MprisPlayer lastActive: null

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
    readonly property string title: titleOf(player)
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property string identity: player?.identity ?? ""
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property bool canSeek: canSeekOf(player)
    readonly property real length: lengthOf(player)

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

    function togglePlaying(p = player) {
        if (p?.canTogglePlaying) {
            p.togglePlaying();
        }
    }

    function next(p = player) {
        if (p?.canGoNext) {
            p.next();
        }
    }

    function previous(p = player) {
        if (p?.canGoPrevious) {
            p.previous();
        }
    }

    function raise(p = player) {
        if (p?.canRaise) {
            p.raise();
        }
    }

    function seek(seconds, p = player) {
        if (canSeekOf(p)) {
            p.position = Math.max(0, Math.min(lengthOf(p), seconds));
        }
    }

    function show(p) {
        pinned = p;
    }

    function cycle() {
        const list = players;
        if (list.length < 2) {
            return;
        }

        const index = list.indexOf(player);
        show(list[(index + 1) % list.length]);
    }

    function titleOf(p) {
        return p ? (p.trackTitle || "Unknown Title") : "";
    }

    function lengthOf(p) {
        return (p?.lengthSupported ?? false) ? p.length : 0;
    }

    function canSeekOf(p) {
        return (p?.canSeek ?? false) && (p?.positionSupported ?? false);
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`;
    }
}
