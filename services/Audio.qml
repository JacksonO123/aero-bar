pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// The default output's volume and mute, plus the helpers the volume flyout uses for any node
// (app streams too).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.audio !== null
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : false
    readonly property string deviceName: sink ? nameOf(sink) : "No audio device"

    // the slider tops out here; volume set above it elsewhere still displays correctly
    property real maxVolume: 1.0

    // volume flyouts currently open; the on-screen volume pop-up stays away while one is
    property int panesOpen: 0

    // a device's display name
    function nameOf(node) {
        return node.description || node.nickname || node.name;
    }

    // any node (the output, or an app's stream). Like Windows, raising it while muted unmutes.
    function setNodeVolume(node, value) {
        if (!node?.audio) {
            return;
        }
        if (node.audio.muted && value > 0) {
            node.audio.muted = false;
        }
        node.audio.volume = value;
    }

    function toggleNodeMute(node) {
        if (node?.audio) {
            node.audio.muted = !node.audio.muted;
        }
    }

    function setVolume(value) {
        if (available) {
            // never above maxVolume, unless it already is (set elsewhere): then don't cut it down
            setNodeVolume(sink, Math.max(0, Math.min(Math.max(maxVolume, volume), value)));
        }
    }

    function adjust(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        toggleNodeMute(sink);
    }

    // pipewire node properties (volume/muted) are only valid while the node is bound
    PwObjectTracker {
        objects: [root.sink]
    }
}
