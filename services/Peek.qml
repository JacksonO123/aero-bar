pragma Singleton

import Quickshell
import QtQuick

// Aero Peek: while a taskbar thumbnail is hovered, show just that window and turn the others
// into glass outlines (modules/aero_bar/peek).
Singleton {
    id: root

    // hyprctl-style address ("0x...") of the window being peeked at, or ""
    property string address: ""

    function show(address) {
        if (root.address === "") {
            HyprState.retain();
        }
        root.address = address;
    }

    function hide() {
        if (root.address !== "") {
            HyprState.release();
        }
        root.address = "";
    }
}
