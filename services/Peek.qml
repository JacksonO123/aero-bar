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

    // the thumbnail flyout's frame that started the peek, and the top-left corner of its window
    // in layout coordinates (like window positions). The overlay cuts a hole there: it is on the
    // same (Top) layer and maps later, so it would otherwise cover the flyout. Kept until the
    // veil has faded out.
    property Item clearItem: null
    property point clearOrigin: Qt.point(0, 0)
    readonly property rect clearRect: {
        const f = clearItem;
        if (!f) {
            return Qt.rect(0, 0, 0, 0);
        }
        f.x, f.y, f.width, f.height; // follow the flyout as it resizes (mapToItem isn't tracked)
        const p = f.mapToItem(null, 0, 0);
        return Qt.rect(clearOrigin.x + p.x, clearOrigin.y + p.y, f.width, f.height);
    }

    // window positions come from HyprState, which only stays fresh while retained
    property bool holding: false

    function hold() {
        if (!holding) {
            HyprState.retain();
            holding = true;
        }
    }

    // a thumbnail is hovered: start fetching window positions now, a peek may follow. Lets go
    // again (after the grace period) if none does.
    function prepare() {
        hold();
        if (!toplevel) {
            releaseTimer.restart();
        }
    }

    function show(t, flyoutFrame, windowOrigin) {
        releaseTimer.stop();
        hold();
        toplevel = t;
        clearItem = flyoutFrame;
        clearOrigin = windowOrigin;
    }

    // stop peeking at `t`, unless another window's peek has taken over already
    function hide(t) {
        if (t !== toplevel) {
            return;
        }
        toplevel = null;
        if (holding) {
            releaseTimer.restart();
        }
    }

    // let go a little later, so sweeping across thumbnails takes one snapshot, not one each
    // (and the veil has faded out by then)
    Timer {
        id: releaseTimer
        interval: 1500
        onTriggered: {
            HyprState.release();
            root.holding = false;
            root.clearItem = null;
        }
    }
}
