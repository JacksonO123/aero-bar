pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Window/workspace/monitor geometry straight from `hyprctl -j`, plus a serialized dispatch queue.
//
// Snapshots are only refreshed on hyprland events while something holds a `retain()`
// (the workspace overview), so this costs nothing while the overview is closed.
Singleton {
    id: root

    property var clients: []
    property var workspaces: []
    property var monitors: []
    property string focusedAddress: ""
    property bool loaded: false

    // `epoch` goes up every time a queued dispatch finishes. Each snapshot remembers the epoch it
    // was started in (`dataEpoch`), so consumers that applied an optimistic change can ignore
    // snapshots that were taken before hyprland actually performed it.
    property int epoch: 0
    property int dataEpoch: -1
    property int runEpoch: 0

    property int watchers: 0
    readonly property bool live: watchers > 0

    property var queue: []
    property bool refreshQueued: false
    property bool awaitingParse: false

    readonly property string separator: "@@AERO_SEP@@"

    signal updated

    function retain() {
        watchers += 1;
        refresh();
    }

    function release() {
        watchers = Math.max(0, watchers - 1);
    }

    function refresh() {
        if (snapshot.running || awaitingParse) {
            refreshQueued = true;
            return;
        }

        runEpoch = epoch;
        awaitingParse = true;
        snapshot.running = true;
    }

    function finishRun() {
        awaitingParse = false;
        watchdog.stop();

        if (refreshQueued) {
            refreshQueued = false;
            Qt.callLater(refresh);
        }
    }

    function parse(text) {
        const parts = text.split(separator);
        if (parts.length < 3) {
            console.warn("[HyprState] unexpected hyprctl output");
            return;
        }

        let rawClients, rawWorkspaces, rawMonitors, rawActive = null;
        try {
            rawClients = JSON.parse(parts[0]);
            rawWorkspaces = JSON.parse(parts[1]);
            rawMonitors = JSON.parse(parts[2]);
        } catch (e) {
            console.warn("[HyprState] could not parse hyprctl json:", e);
            return;
        }

        try {
            rawActive = JSON.parse(parts[3]);
        } catch (e) {
            rawActive = null;
        }

        const isSpecial = name => String(name ?? "").startsWith("special");

        monitors = rawMonitors.filter(m => !m.disabled).map(m => {
            const rotated = (m.transform ?? 0) % 2 === 1;
            const scale = m.scale > 0 ? m.scale : 1;
            return {
                id: m.id,
                name: m.name,
                x: m.x,
                y: m.y,
                width: (rotated ? m.height : m.width) / scale,
                height: (rotated ? m.width : m.height) / scale,
                reserved: Array.isArray(m.reserved) ? m.reserved : [0, 0, 0, 0],
                activeWorkspaceId: m.activeWorkspace ? m.activeWorkspace.id : -1,
                focused: !!m.focused
            };
        });

        workspaces = rawWorkspaces.filter(w => w.id !== -1 && !isSpecial(w.name)).map(w => ({
                    id: w.id,
                    name: String(w.name),
                    monitorId: w.monitorID ?? -1
                })).sort((a, b) => a.id - b.id);

        clients = rawClients.filter(c => c.mapped !== false && !c.hidden && c.workspace && c.workspace.id !== -1 && !isSpecial(c.workspace.name) && Array.isArray(c.at) && Array.isArray(c.size)).map(c => ({
                    address: c.address,
                    cls: c.class || c.initialClass || "",
                    title: c.title || c.initialTitle || "",
                    wsId: c.workspace.id,
                    x: c.at[0],
                    y: c.at[1],
                    w: c.size[0],
                    h: c.size[1],
                    floating: !!c.floating,
                    fullscreen: typeof c.fullscreen === "number" ? c.fullscreen > 0 : !!c.fullscreen,
                    monitorId: c.monitor ?? -1,
                    focusHistoryId: c.focusHistoryID ?? 99
                })).sort((a, b) => (a.wsId - b.wsId) || (b.focusHistoryId - a.focusHistoryId));

        focusedAddress = rawActive?.address ?? "";
        dataEpoch = runEpoch;
        loaded = true;
        updated();
    }

    // ---- dispatching ----------------------------------------------------------------------

    // Queues a command and returns the epoch that will be reached once it has run.
    function enqueue(argv) {
        queue.push(argv);
        const target = epoch + queue.length + (dispatcher.running ? 1 : 0);
        pump();
        return target;
    }

    function pump() {
        if (dispatcher.running || queue.length === 0) {
            return;
        }

        dispatcher.command = queue.shift();
        dispatcher.running = true;
    }

    // Hyprland's newer Lua config takes Lua dispatchers over IPC (`hl.dsp.*`) instead of the classic
    // `movetoworkspacesilent ...` strings, so commands are described as ops and rendered for
    // whichever config this hyprland is running. (`usingLua` only exists on quickshell >= 0.3.)
    readonly property bool lua: Hyprland.usingLua ?? false

    function luaString(value) {
        return JSON.stringify(String(value));
    }

    function renderClassic(op) {
        switch (op.op) {
        case "moveToWorkspace":
            return `movetoworkspacesilent ${op.workspace},address:${op.address}`;
        case "moveTo":
            return `movewindowpixel exact ${Math.round(op.x)} ${Math.round(op.y)},address:${op.address}`;
        case "resizeTo":
            return `resizewindowpixel exact ${Math.round(op.w)} ${Math.round(op.h)},address:${op.address}`;
        case "resizeBy":
            return `resizewindowpixel ${Math.round(op.dx)} ${Math.round(op.dy)},address:${op.address}`;
        case "focusWindow":
            return `focuswindow address:${op.address}`;
        case "focusWorkspace":
            return `workspace ${op.workspace}`;
        case "close":
            return `closewindow address:${op.address}`;
        case "exit":
            return "exit";
        case "swapWith":
            return `swapwindow address:${op.address}`;
        }
        return "";
    }

    function renderLua(op) {
        const win = luaString(`address:${op.address}`);
        switch (op.op) {
        case "moveToWorkspace":
            return `hl.dsp.window.move({ window = ${win}, workspace = ${luaString(op.workspace)}, follow = false })`;
        case "moveTo":
            return `hl.dsp.window.move({ window = ${win}, x = ${Math.round(op.x)}, y = ${Math.round(op.y)}, relative = false })`;
        case "resizeTo":
            return `hl.dsp.window.resize({ window = ${win}, x = ${Math.round(op.w)}, y = ${Math.round(op.h)}, relative = false })`;
        case "resizeBy":
            return `hl.dsp.window.resize({ window = ${win}, x = ${Math.round(op.dx)}, y = ${Math.round(op.dy)}, relative = true })`;
        case "focusWindow":
            return `hl.dsp.focus({ window = ${win} })`;
        case "focusWorkspace":
            return `hl.dsp.focus({ workspace = ${luaString(op.workspace)} })`;
        case "close":
            return `hl.dsp.window.close({ window = ${win} })`;
        case "exit":
            return "hl.dsp.exit()";
        case "swapWith":
            return `hl.dsp.window.swap({ target = ${win} })`;
        }
        return "";
    }

    // Runs ops as one IPC request; `restoreCursor` puts the pointer back afterwards (focus changes warp it).
    function dispatch(ops, restoreCursor) {
        const list = Array.isArray(ops) ? ops : [ops];

        if (lua) {
            const chunk = list.map(op => `hl.dispatch(${renderLua(op)})`).join("; ");
            return enqueue(["hyprctl", "eval", chunk]);
        }

        const batch = list.map(op => `dispatch ${renderClassic(op)}`).join(" ; ");
        if (restoreCursor) {
            // the batch goes in as $1, so the shell never interprets workspace names etc.
            return enqueue(["sh", "-c", 'pos=$(hyprctl cursorpos | tr -d ","); hyprctl --batch "$1 ; dispatch movecursor $pos"', "sh", batch]);
        }
        return enqueue(["hyprctl", "--batch", batch]);
    }

    function workspaceSelector(id, name) {
        return id > 0 ? String(id) : `name:${name}`;
    }

    function activeWorkspaceSelector() {
        const monitor = monitors.find(m => m.focused);
        if (!monitor) {
            return "";
        }

        const ws = workspaces.find(w => w.id === monitor.activeWorkspaceId);
        return ws ? workspaceSelector(ws.id, ws.name) : String(monitor.activeWorkspaceId);
    }

    function focusWindow(address) {
        return dispatch({
            op: "focusWindow",
            address
        });
    }

    function closeWindow(address) {
        return dispatch({
            op: "close",
            address
        });
    }

    function focusWorkspace(selector) {
        return dispatch({
            op: "focusWorkspace",
            workspace: selector
        });
    }

    function moveToWorkspace(address, selector, floatingPos) {
        const ops = [
            {
                op: "moveToWorkspace",
                address,
                workspace: selector
            }
        ];
        if (floatingPos) {
            ops.push({
                op: "moveTo",
                address,
                x: floatingPos.x,
                y: floatingPos.y
            });
        }
        return dispatch(ops);
    }

    function moveFloating(address, x, y) {
        return dispatch({
            op: "moveTo",
            address,
            x,
            y
        });
    }

    function setFloatingGeometry(address, x, y, w, h) {
        return dispatch([
            {
                op: "resizeTo",
                address,
                w,
                h
            },
            {
                op: "moveTo",
                address,
                x,
                y
            }
        ]);
    }

    // For tiled windows hyprland treats a resize delta as "move the split by this much"
    // (dwindle split ratio / master factor), so dx/dy here are divider movements.
    function moveDividers(commands) {
        return dispatch(commands.map(c => ({
                        op: "resizeBy",
                        address: c.address,
                        dx: c.dx,
                        dy: c.dy
                    })));
    }

    // swapping only operates on the focused window, so focus A, swap with B, then put focus
    // (and the cursor, which focusing warps) back where they were
    function swapWindows(a, b) {
        const ops = [
            {
                op: "focusWindow",
                address: a
            },
            {
                op: "swapWith",
                address: b
            }
        ];

        if (focusedAddress && focusedAddress !== a) {
            ops.push({
                op: "focusWindow",
                address: focusedAddress
            });
        } else if (!focusedAddress) {
            const selector = activeWorkspaceSelector();
            if (selector) {
                ops.push({
                    op: "focusWorkspace",
                    workspace: selector
                });
            }
        }

        return dispatch(ops, true);
    }

    // ---- processes -------------------------------------------------------------------------

    Process {
        id: snapshot
        command: ["sh", "-c", `hyprctl -j clients; echo ${root.separator}; hyprctl -j workspaces; echo ${root.separator}; hyprctl -j monitors; echo ${root.separator}; hyprctl -j activewindow`]

        stdout: StdioCollector {
            onStreamFinished: {
                root.parse(text);
                root.finishRun();
            }
        }

        // in case stdout never reports the end of the stream
        onExited: watchdog.restart()
    }

    Timer {
        id: watchdog
        interval: 800
        onTriggered: {
            if (root.awaitingParse) {
                root.finishRun();
            }
        }
    }

    Process {
        id: dispatcher

        onExited: {
            root.epoch += 1;
            // nobody reads a snapshot unless something holds a retain(); the dispatch's own
            // events restart the same debounce, so this gives one snapshot, not two
            if (root.live) {
                eventDebounce.restart();
            }
            Qt.callLater(root.pump);
        }
    }

    Timer {
        id: eventDebounce
        interval: 50
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        enabled: root.live

        function onRawEvent(event) {
            eventDebounce.restart();
        }
    }
}
