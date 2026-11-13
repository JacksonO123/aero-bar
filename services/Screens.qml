pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Which screen a pop-up (start menu, dialogs, balloons, OSD) shows on.
Singleton {
    // the focused monitor, else the first screen
    readonly property string focused: Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""

    // `name` if that screen is still connected, otherwise the focused one
    function resolve(name) {
        return Quickshell.screens.some(s => s.name === name) ? name : focused;
    }
}
