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
    readonly property string deviceName: sink ? nameOf(sink) : "No audio device"

    property real maxVolume: 1.0

    property int panesOpen: 0

    function nameOf(node) {
        return node.description || node.nickname || node.name;
    }

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
            // don't cut down a volume already set above maxVolume elsewhere
            setNodeVolume(sink, Math.max(0, Math.min(Math.max(maxVolume, volume), value)));
        }
    }

    function adjust(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        toggleNodeMute(sink);
    }

    // PwNode audio properties are only valid while the node is bound
    PwObjectTracker {
        objects: [root.sink]
    }
}
