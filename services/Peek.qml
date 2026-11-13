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

    // the thumbnail flyout that started the peek, in layout coordinates (like window positions;
    // the flyout keeps it current). The overlay leaves it uncovered: both are on the Top layer
    // and the overlay maps later. Kept after hide() so the hole stays while the veil fades out.
    property rect clearRect: Qt.rect(0, 0, 0, 0)

    // window positions come from HyprState, which only stays fresh while retained
    property bool holding: false

    // a thumbnail is hovered: start fetching window positions now, a peek may follow. Lets go
    // again (after the grace period) if none does.
    function prepare() {
        if (!holding) {
            HyprState.retain();
            holding = true;
        }
        if (!toplevel) {
            releaseTimer.restart();
        }
    }

    function show(t) {
        releaseTimer.stop();
        if (!holding) {
            HyprState.retain();
            holding = true;
        }
        toplevel = t;
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
