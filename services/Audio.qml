pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.audio !== null
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : false
    readonly property string deviceName: sink ? (sink.description || sink.nickname || sink.name) : "No audio device"

    // the slider tops out here; volume set above it elsewhere still displays correctly
    property real maxVolume: 1.0

    // volume flyouts currently open; the on-screen volume pop-up stays away while one is
    property int flyoutsOpen: 0

    function setVolume(value) {
        if (!available) {
            return;
        }

        // never above maxVolume, unless it already is (set elsewhere): then don't cut it down
        const next = Math.max(0, Math.min(Math.max(maxVolume, volume), value));

        // like Windows: dragging the slider while muted unmutes
        if (sink.audio.muted && next > 0) {
            sink.audio.muted = false;
        }

        sink.audio.volume = next;
    }

    function adjust(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        if (available) {
            sink.audio.muted = !sink.audio.muted;
        }
    }

    // pipewire node properties (volume/muted) are only valid while the node is bound
    PwObjectTracker {
        objects: [root.sink]
    }
}
