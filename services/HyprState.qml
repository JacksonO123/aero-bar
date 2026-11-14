pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property var clients: []
    property var workspaces: []
    property var monitors: []
    property string focusedAddress: ""
    readonly property bool loaded: dataEpoch >= 0

    signal updated

    function clientAt(address) {
        return clients.find(c => c.address === address) ?? null;
    }

    // epoch counts finished dispatches; snapshots record the epoch they started in
    property int epoch: 0
    property int dataEpoch: -1
    property int runEpoch: 0

    property int watchers: 0
    readonly property bool live: watchers > 0

    // without these, title events are skipped: apps can retitle many times a second
    property int titleWatchers: 0

    function retain(titles) {
        watchers += 1;
        if (titles) {
            titleWatchers += 1;
        }
        refresh();
    }

    function release(titles) {
        watchers = Math.max(0, watchers - 1);
        if (titles) {
            titleWatchers = Math.max(0, titleWatchers - 1);
        }
        if (watchers === 0) {
            eventDebounce.stop();
            maxWait.stop();
        }
    }

    property bool awaitingParse: false
    property bool refreshQueued: false
    // hyprctl --batch puts this between the replies
    readonly property string separator: "\n\n\n"

    function refresh() {
        eventDebounce.stop();
        maxWait.stop();

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

    function isSpecial(ws) {
        return ws.type ? ws.type === "special" : String(ws.name ?? "").startsWith("special");
    }

    // newer Hyprland gives named workspaces no "id", only an "address"
    property var namedKeys: Object.create(null)

    function workspaceKey(ws) {
        if (typeof ws.id === "number") {
            return ws.id;
        }

        const address = ws.address ?? ws.name ?? "";
        if (!(address in namedKeys)) {
            namedKeys[address] = -200000 - Object.keys(namedKeys).length;
        }
        return namedKeys[address];
    }

    // a Quickshell HyprlandWorkspace's key (its id is -1 for named workspaces)
    function keyOf(qsWorkspace) {
        return qsWorkspace.id !== -1 ? qsWorkspace.id : workspaceKey({
            address: qsWorkspace.address
        });
    }

    // name: matches a workspace's address, not its display name
    function selectorOf(ws) {
        return ws.id > 0 ? String(ws.id) : `name:${ws.address ?? ws.name}`;
    }

    function isShownClient(c) {
        return c.mapped !== false && !c.hidden && c.workspace && c.workspace.id !== -1 && !isSpecial(c.workspace) && Array.isArray(c.at) && Array.isArray(c.size);
    }

    function parseMonitors(raw) {
        return raw.filter(m => !m.disabled).map(m => {
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
                activeWorkspaceId: m.activeWorkspace ? workspaceKey(m.activeWorkspace) : -1,
                focused: !!m.focused
            };
        });
    }

    function parseWorkspaces(raw) {
        return raw.filter(w => w.id !== -1 && !isSpecial(w)).map(w => ({
                    id: workspaceKey(w),
                    name: String(w.name),
                    selector: selectorOf(w),
                    layout: String(w.tiledLayout ?? ""),
                    monitorId: w.monitorID ?? -1
                })).sort((a, b) => a.id - b.id);
    }

    // least recently focused first, so the focused window draws on top
    function parseClients(raw) {
        return raw.filter(isShownClient).map(c => ({
                    address: c.address,
                    cls: c.class || c.initialClass || "",
                    title: c.title || c.initialTitle || "",
                    wsId: workspaceKey(c.workspace),
                    x: c.at[0],
                    y: c.at[1],
                    w: c.size[0],
                    h: c.size[1],
                    floating: !!c.floating,
                    fullscreen: typeof c.fullscreen === "number" ? c.fullscreen > 0 : !!c.fullscreen,
                    monitorId: c.monitor ?? -1,
                    focusHistoryId: c.focusHistoryID ?? 99
                })).sort((a, b) => (a.wsId - b.wsId) || (b.focusHistoryId - a.focusHistoryId));
    }

    function parse(text) {
        const parts = text.split(separator);
        if (parts.length < 3) {
            console.warn("[HyprState] unexpected hyprctl output");
            return;
        }

        let rawClients, rawWorkspaces, rawMonitors;
        try {
            rawClients = JSON.parse(parts[0]);
            rawWorkspaces = JSON.parse(parts[1]);
            rawMonitors = JSON.parse(parts[2]);
        } catch (e) {
            console.warn("[HyprState] could not parse hyprctl json:", e);
            return;
        }

        // an unparsable active window just means nothing is focused
        let rawActive = null;
        try {
            rawActive = JSON.parse(parts[3]);
        } catch (e) {}

        monitors = parseMonitors(rawMonitors);
        workspaces = parseWorkspaces(rawWorkspaces);
        clients = parseClients(rawClients);
        focusedAddress = rawActive?.address ?? "";
        dataEpoch = runEpoch;
        updated();
    }

    property var queue: []

    // Lua configs take hl.dsp.* over IPC; usingLua needs quickshell >= 0.3
    readonly property bool lua: Hyprland.usingLua ?? false

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

    // Lua escapes: JSON's \\u0001 form isn't valid Lua
    function luaString(value) {
        const escaped = String(value).replace(/[\\"]/g, c => "\\" + c).replace(/[\x00-\x1f\x7f]/g, c => "\\" + String(c.charCodeAt(0)).padStart(3, "0"));
        return `"${escaped}"`;
    }

    function luaWindow(address) {
        return luaString(`address:${address}`);
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
        const win = luaWindow(op.address);
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
        case "swapPair":
            return `hl.dsp.window.swap({ window = ${win}, target = ${luaWindow(op.target)} })`;
        }
        return "";
    }

    // restoreCursor: focusing and swapping warp the pointer
    function dispatch(ops, restoreCursor) {
        const list = Array.isArray(ops) ? ops : [ops];

        if (lua) {
            let chunk = list.map(op => `hl.dispatch(${renderLua(op)})`).join("; ");
            if (restoreCursor) {
                chunk = `local p = hl.get_cursor_pos(); ${chunk}; if p then hl.dispatch(hl.dsp.cursor.move({ x = p.x, y = p.y })) end`;
            }
            return enqueue(["hyprctl", "eval", chunk]);
        }

        const batch = list.map(op => `dispatch ${renderClassic(op)}`).join(" ; ");
        if (restoreCursor) {
            // batch passed as $1 so the shell never interprets it
            return enqueue(["sh", "-c", 'pos=$(hyprctl cursorpos | tr -d ","); hyprctl --batch "$1 ; dispatch movecursor $pos"', "sh", batch]);
        }
        return enqueue(["hyprctl", "--batch", batch]);
    }

    // "" for a named workspace that's gone
    function workspaceSelector(id) {
        return workspaces.find(w => w.id === id)?.selector ?? (id > 0 ? String(id) : "");
    }

    function activeWorkspaceSelector() {
        const monitor = monitors.find(m => m.focused);
        if (!monitor) {
            return "";
        }

        return workspaceSelector(monitor.activeWorkspaceId);
    }

    function focusWindow(address) {
        return dispatch({
            op: "focusWindow",
            address
        });
    }

    function closeWindow(address) {
        closeWindows([address]);
    }

    function closeWindows(addresses) {
        const known = addresses.filter(address => address !== "");
        if (known.length > 0) {
            dispatch(known.map(address => ({
                        op: "close",
                        address
                    })));
        }
    }

    function focusWorkspace(selector) {
        if (!selector) {
            return epoch;
        }
        return dispatch({
            op: "focusWorkspace",
            workspace: selector
        });
    }

    function moveToWorkspace(address, selector, floatingPos) {
        if (!selector) {
            return epoch;
        }
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

    // for tiled windows hyprland turns a resize delta into a divider move
    function moveDividers(commands) {
        return dispatch(commands.map(c => ({
                    op: "resizeBy",
                    address: c.address,
                    dx: c.dx,
                    dy: c.dy
                })));
    }

    function swapWindows(a, b) {
        if (lua) {
            const ops = [
                {
                    op: "swapPair",
                    address: a,
                    target: b
                }
            ];
            // the swap keeps focus, so a focused window sent to a hidden workspace keeps it
            const other = focusedAddress === a ? b : focusedAddress === b ? a : "";
            if (other && clientAt(a)?.wsId !== clientAt(b)?.wsId) {
                ops.push({
                    op: "focusWindow",
                    address: other
                });
            }
            return dispatch(ops, true);
        }

        // classic swapwindow acts on the focused window: focus one that's already showing, if
        // either is, so no monitor switches workspace
        const shown = new Set(monitors.map(m => m.activeWorkspaceId));
        if (!shown.has(clientAt(a)?.wsId) && shown.has(clientAt(b)?.wsId)) {
            [a, b] = [b, a];
        }

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

        if (!focusedAddress) {
            const selector = activeWorkspaceSelector();
            if (selector) {
                ops.push({
                    op: "focusWorkspace",
                    workspace: selector
                });
            }
        } else if (focusedAddress !== a) {
            ops.push({
                op: "focusWindow",
                address: focusedAddress
            });
        } else if (clientAt(a)?.wsId !== clientAt(b)?.wsId) {
            ops.push({
                op: "focusWindow",
                address: b
            });
        }

        return dispatch(ops, true);
    }

    Process {
        id: snapshot
        command: ["hyprctl", "--batch", "j/clients; j/workspaces; j/monitors; j/activewindow"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.parse(text);
                root.finishRun();
            }
        }

        // recovers if parse() throws before finishRun()
        onExited: {
            if (root.awaitingParse) {
                watchdog.restart();
            }
        }
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

        stdout: StdioCollector {
            onStreamFinished: {
                const problems = text.split("\n").map(line => line.trim()).filter(line => line !== "" && line !== "ok");
                if (problems.length > 0) {
                    console.warn("[HyprState] hyprctl:", problems.join(" | "));
                }
            }
        }

        onExited: {
            root.epoch += 1;
            if (root.live) {
                root.scheduleRefresh();
            }
            Qt.callLater(root.pump);
        }
    }

    // maxWait caps the debounce so a stream of events can't postpone it forever
    function scheduleRefresh() {
        eventDebounce.restart();
        if (!maxWait.running) {
            maxWait.start();
        }
    }

    Timer {
        id: eventDebounce
        interval: 50
        onTriggered: root.refresh()
    }

    Timer {
        id: maxWait
        interval: 200
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        enabled: root.live

        function onRawEvent(event) {
            if (root.titleWatchers === 0 && (event.name === "windowtitle" || event.name === "windowtitlev2")) {
                return;
            }
            root.scheduleRefresh();
        }
    }
}
