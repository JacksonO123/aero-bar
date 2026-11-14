pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// qs ipc call session shutDown | restart | logOff
Singleton {
    id: root

    // "shutDown" | "restart" | "logOff": the last one started
    property string action: "shutDown"
    // "" | "closing" | "blocked" | "ending"
    property string phase: ""
    readonly property bool active: phase !== ""
    readonly property bool blocked: phase === "blocked"

    // only real windows: Hyprland also lists hidden X11 windows (never closed) and popups
    readonly property var windows: Taskbar.toplevels.filter(t => t.wayland)

    onWindowsChanged: finishIfClosed()

    function start(kind) {
        if (active) {
            return;
        }

        action = kind;
        phase = "closing";
        HyprState.closeWindows(windows.map(Taskbar.hyprAddress));
        patience.restart();
        finishIfClosed();
    }

    function finishIfClosed() {
        if (windows.length === 0) {
            finish();
        }
    }

    function finish() {
        if (!active || phase === "ending") {
            return;
        }

        phase = "ending";
        patience.stop();
        farewell.start();
    }

    function cancel() {
        if (phase === "ending") {
            return;
        }

        patience.stop();
        phase = "";
    }

    Timer {
        id: patience
        interval: 5000
        onTriggered: {
            if (root.phase === "closing") {
                root.phase = "blocked";
            }
        }
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
        onTriggered: root.phase = ""
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
