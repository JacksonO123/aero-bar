pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var toplevel: null
    readonly property string address: Taskbar.hyprAddress(toplevel)

    // overlay maps later on the same layer, so it cuts a hole here for the flyout
    property Item clearItem: null
    property point clearOrigin: Qt.point(0, 0)
    readonly property rect clearRect: {
        const f = clearItem;
        if (!f) {
            return Qt.rect(0, 0, 0, 0);
        }
        f.x, f.y, f.width, f.height; // mapToItem isn't tracked by bindings
        const p = f.mapToItem(null, 0, 0);
        return Qt.rect(clearOrigin.x + p.x, clearOrigin.y + p.y, f.width, f.height);
    }

    property bool holding: false

    function hold() {
        if (!holding) {
            HyprState.retain();
            holding = true;
        }
    }

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

    function hide(t) {
        if (t !== toplevel) {
            return;
        }
        toplevel = null;
        if (holding) {
            releaseTimer.restart();
        }
    }

    // delayed: one snapshot covers a sweep across thumbnails; veil fades first
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
