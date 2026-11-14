pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    readonly property string focused: Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""

    function resolve(name) {
        return Quickshell.screens.some(s => s.name === name) ? name : focused;
    }
}
