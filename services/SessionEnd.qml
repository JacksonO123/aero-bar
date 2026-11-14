pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// qs ipc call session shutDown | restart | logOff
Singleton {
    id: root

    // "shutDown" | "restart" | "logOff", "" while the session goes on
    property string action: ""
    readonly property bool active: action !== ""
    property bool blocked: false
    property bool ending: false

    readonly property var windows: Hyprland.toplevels.values

    onWindowsChanged: finishIfClosed()

    function start(kind) {
        if (active) {
            return;
        }

        action = kind;
        blocked = false;
        ending = false;
        const closing = windows.map(t => ({
                    op: "close",
                    address: Taskbar.hyprAddress(t)
                })).filter(op => op.address !== "");
        if (closing.length > 0) {
            HyprState.dispatch(closing);
        }
        patience.restart();
        finishIfClosed();
    }

    function finishIfClosed() {
        if (active && !ending && windows.length === 0) {
            finish();
        }
    }

    function finish() {
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
        action = "";
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
            root.action = "";
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
