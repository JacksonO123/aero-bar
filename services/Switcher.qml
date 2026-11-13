pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Alt+Tab and Win7's Flip 3D (Super+Tab) over every window, most recently used first.
//
// hyprland.conf:
//   bind  = ALT, TAB, global, quickshell:alttab
//   bind  = ALT SHIFT, TAB, global, quickshell:alttab-back
//   bind  = SUPER, TAB, global, quickshell:flip3d
//   bind  = SUPER SHIFT, TAB, global, quickshell:flip3d-back
//   # switch when the modifier is let go (the switcher also watches for it itself)
//   bindr = ALT, ALT_L, global, quickshell:switcher-commit
//   bindr = SUPER, SUPER_L, global, quickshell:switcher-commit
// Note: the start menu's `bindr = SUPER, SUPER_L` also fires on that release; it is ignored
// while the switcher is open.
Singleton {
    id: root

    // "" | "alttab" | "flip"
    property string mode: ""
    readonly property bool active: mode !== ""
    property string screenName: ""
    // the selected window's address (Hyprland toplevel form, no "0x")
    property string selected: ""
    // when the switcher closed (the start menu ignores the Super release right after Flip 3D)
    property double closedAt: 0

    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace && !String(t.workspace.name ?? "").startsWith("special") && t.workspace.id !== -1).sort((a, b) => historyOf(a) - historyOf(b))
    readonly property int index: Math.max(0, windows.findIndex(t => t.address === selected))
    readonly property var current: windows[index] ?? null

    function historyOf(t) {
        return t.activated ? -1 : (t.lastIpcObject?.focusHistoryID ?? 99);
    }

    function start(m) {
        if (active) {
            step(1);
            return;
        }
        Hyprland.refreshToplevels();
        if (windows.length === 0) {
            return;
        }
        screenName = Hyprland.focusedMonitor?.name ?? "";
        // like Windows: the first press lands on the previous window
        selected = (windows[windows.length > 1 ? 1 : 0]).address;
        mode = m;
    }

    function step(delta) {
        if (!active || windows.length === 0) {
            return;
        }
        const n = windows.length;
        selected = windows[((index + delta) % n + n) % n].address;
    }

    function select(t) {
        if (t) {
            selected = t.address;
        }
    }

    function commit() {
        if (!active) {
            return;
        }
        const t = current;
        close();
        if (t) {
            HyprState.focusWindow("0x" + t.address);
        }
    }

    function close() {
        mode = "";
        closedAt = Date.now();
        Peek.hide();
        Hyprland.refreshToplevels();
    }

    GlobalShortcut {
        name: "alttab"
        description: "Alt+Tab window switcher"
        onPressed: root.mode === "flip" ? root.step(1) : root.start("alttab")
    }

    GlobalShortcut {
        name: "alttab-back"
        description: "Alt+Tab, backwards"
        onPressed: root.active ? root.step(-1) : root.start("alttab")
    }

    GlobalShortcut {
        name: "flip3d"
        description: "Flip 3D window switcher"
        onPressed: root.mode === "alttab" ? root.step(1) : root.start("flip")
    }

    GlobalShortcut {
        name: "flip3d-back"
        description: "Flip 3D, backwards"
        onPressed: root.active ? root.step(-1) : root.start("flip")
    }

    GlobalShortcut {
        name: "switcher-commit"
        description: "Switch to the selected window (bind to the modifier's release)"
        onPressed: root.commit()
    }

    IpcHandler {
        target: "switcher"

        function alttab(): void {
            root.start("alttab");
        }
        function flip(): void {
            root.start("flip");
        }
        function next(): void {
            root.step(1);
        }
        function prev(): void {
            root.step(-1);
        }
        function commit(): void {
            root.commit();
        }
        function cancel(): void {
            root.close();
        }
    }
}
