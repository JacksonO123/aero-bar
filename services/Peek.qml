pragma Singleton

import Quickshell
import QtQuick

// Aero Peek: while a taskbar thumbnail is hovered, show just that window and turn the others
// into glass outlines (modules/aero_bar/peek).
Singleton {
    id: root

    // the Hyprland toplevel being peeked at, or null
    property var toplevel: null
    // hyprctl-style address, to find its geometry in HyprState
    readonly property string address: Taskbar.hyprAddress(toplevel)

    // the thumbnail flyout that started the peek, in layout coordinates (like window positions).
    // The overlay leaves it uncovered: both are on the Top layer and the overlay maps later.
    // Kept after hide() so the hole stays while the veil fades out.
    property rect clearRect: Qt.rect(0, 0, 0, 0)

    // window positions come from HyprState, which only stays fresh while retained
    property bool holding: false

    function show(t, rect) {
        releaseTimer.stop();
        if (!holding) {
            HyprState.retain();
            holding = true;
        }
        toplevel = t;
        clearRect = rect;
    }

    function hide() {
        toplevel = null;
        if (holding) {
            releaseTimer.restart();
        }
    }

    // stay fresh a little longer, so sweeping across thumbnails takes one snapshot, not one each
    Timer {
        id: releaseTimer
        interval: 1500
        onTriggered: {
            HyprState.release();
            root.holding = false;
        }
    }
}
