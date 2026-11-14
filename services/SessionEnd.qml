pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// qs ipc call session shutDown | restart | logOff
Singleton {
    id: root

    // "shutDown" | "restart" | "logOff": the last one started
    property string action: "shutDown"
    property bool active: false
    property bool blocked: false
    property bool ending: false

    // only real windows: Hyprland also lists hidden X11 windows (never closed) and popups
    readonly property var windows: Taskbar.toplevels.filter(t => t.wayland)

    onWindowsChanged: finishIfClosed()

    function start(kind) {
        if (active) {
            return;
        }

        action = kind;
        active = true;
        ending = false;
        HyprState.closeWindows(windows.map(Taskbar.hyprAddress));
        patience.restart();
        finishIfClosed();
    }

    function finishIfClosed() {
        if (active && !ending && windows.length === 0) {
            finish();
        }
    }

    function finish() {
        if (!active || ending) {
            return;
        }

        ending = true;
        blocked = false;
        patience.stop();
        farewell.start();
    }

    function cancel() {
        if (ending) {
            return;
        }

        patience.stop();
        blocked = false;
        active = false;
    }

    Timer {
        id: patience
        interval: 5000
        onTriggered: root.blocked = true
    }

    // let "Shutting down…" show before the screens go
    Timer {
        id: farewell
        interval: 900
        onTriggered: {
            if (root.action === "logOff") {
                HyprState.dispatch({
                    op: "exit"
                });
            } else {
                Quickshell.execDetached(["systemctl", root.action === "restart" ? "reboot" : "poweroff"]);
            }
            stalled.start();
        }
    }

    // systemctl refused (e.g. another session is logged in): back to the desktop
    Timer {
        id: stalled
        interval: 20000
        onTriggered: {
            root.ending = false;
            root.active = false;
        }
    }

    IpcHandler {
        target: "session"

        function shutDown(): void {
            root.start("shutDown");
        }

        function restart(): void {
            root.start("restart");
        }

        function logOff(): void {
            root.start("logOff");
        }
    }
}
