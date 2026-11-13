pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../components"
import "../../../services"
import "../../../utils/constants.js" as Constants

// Mini desktops for every workspace, popped up above the workspace buttons after hovering them.
//
//  - drag a window onto another workspace (its card or its taskbar button) to move it there
//  - drop it on the middle of another window to swap the two
//  - drop it on "+" to send it to a new workspace
//  - drag an inner edge of a tiled window (any edge/corner of a floating one) to resize
//  - click a window to focus it, middle click (or the close button) to close it
//  - click a card to switch to that workspace
//
// Every window lives in one layer above the cards so a moved window can fly from one card to
// another. Geometry is in hyprland's global logical pixels (gx/gy/gw/gh) and is only mapped
// into card space for display.
Item {
    id: root

    required property Item anchorItem

    readonly property alias maskItem: maskProxy
    readonly property alias windowLayerItem: windowLayer
    property bool open: false

    // ---- layout tunables
    readonly property real maxDeskW: 216
    readonly property real maxDeskH: 128
    readonly property real cardSpacing: 14
    readonly property real headerH: 20
    readonly property real pad: 10
    readonly property real newCardW: 34
    readonly property real edgeMargin: 10

    // ---- hyprland state
    readonly property string focusedAddress: HyprState.focusedAddress
    readonly property var activeWorkspaceIds: HyprState.monitors.map(m => m.activeWorkspaceId)
    readonly property int focusedWorkspaceId: HyprState.monitors.find(m => m.focused)?.activeWorkspaceId ?? -99999
    property var windowCounts: ({})
    property var layout: ({
            entries: [],
            byId: ({}),
            newCard: ({
                    x: 0,
                    y: 0,
                    w: 0,
                    h: 0
                }),
            width: 200,
            height: 100
        })

    // ---- interaction state
    property var dragInfo: null
    property var resizeInfo: null
    property var dropTarget: null
    property point pointer: Qt.point(0, 0)
    property int hoveredWorkspaceId: -99999
    readonly property bool resizing: resizeInfo !== null
    readonly property bool interacting: dragInfo !== null || resizeInfo !== null
    property bool syncPending: false
    // snapshots older than this predate our last dispatch and would undo the optimistic update
    property int requiredEpoch: 0

    readonly property int highlightedWorkspaceId: dropTarget ? (dropTarget.wsId ?? -99999) : hoveredWorkspaceId

    implicitHeight: frame.height

    ListModel {
        id: wsModel
    }

    ListModel {
        id: winModel
    }

    // ---- open / close ----------------------------------------------------------------------

    readonly property bool triggerHovered: anchorItem.hovered ?? false
    readonly property bool frameHovered: frame.hovered

    onTriggerHoveredChanged: {
        if (triggerHovered) {
            closeTimer.stop();
            if (!open) {
                openTimer.restart();
                HyprState.refresh(); // prefetch so the cards are ready when it opens
            }
        } else {
            openTimer.stop();
            scheduleClose();
        }
    }

    onFrameHoveredChanged: frameHovered ? closeTimer.stop() : scheduleClose()

    onOpenChanged: {
        if (open) {
            HyprState.retain();
        } else {
            HyprState.release();
            hoveredWorkspaceId = -99999;
        }
    }

    Component.onDestruction: {
        if (open) {
            HyprState.release();
        }
    }

    function scheduleClose() {
        if (open && !triggerHovered && !frameHovered && !interacting) {
            closeTimer.restart();
        }
    }

    Connections {
        target: root.anchorItem

        // clicking a workspace button means "take me there", not "show me the overview"
        function onButtonClicked() {
            if (!root.open && root.triggerHovered) {
                openTimer.restart();
            }
        }
    }

    Timer {
        id: openTimer
        interval: Constants.OVERVIEW_HOVER_DELAY
        onTriggered: root.open = true
    }

    Timer {
        id: closeTimer
        interval: 450
        onTriggered: {
            if (!root.interacting && !root.frameHovered && !root.triggerHovered) {
                root.open = false;
            }
        }
    }

    Binding {
        target: root.anchorItem
        property: "highlightWorkspaceId"
        value: root.open ? root.highlightedWorkspaceId : -99999
    }

    // ---- syncing ---------------------------------------------------------------------------

    Connections {
        target: HyprState

        function onUpdated() {
            if (root.interacting || HyprState.dataEpoch < root.requiredEpoch) {
                root.syncPending = true;
                return;
            }
            root.sync();
        }
    }

    Component.onCompleted: {
        if (HyprState.loaded) {
            sync();
        }
    }

    onWidthChanged: {
        if (HyprState.loaded) {
            layout = computeLayout(HyprState.workspaces);
        }
    }

    function sync() {
        syncPending = false;

        const workspaces = HyprState.workspaces;
        const known = new Set(workspaces.map(w => w.id));
        const counts = {};
        for (const c of HyprState.clients) {
            counts[c.wsId] = (counts[c.wsId] ?? 0) + 1;
        }

        // layout first so cards/windows never point at a workspace the layout doesn't know yet
        layout = computeLayout(workspaces);
        windowCounts = counts;

        syncModel(wsModel, workspaces.map(w => ({
                    wsId: w.id,
                    name: w.name,
                    monitorId: w.monitorId
                })), "wsId");

        syncModel(winModel, HyprState.clients.filter(c => known.has(c.wsId)).map(c => ({
                    address: c.address,
                    cls: c.cls,
                    title: c.title,
                    wsId: c.wsId,
                    gx: c.x,
                    gy: c.y,
                    gw: c.w,
                    gh: c.h,
                    floating: c.floating,
                    fullscreen: c.fullscreen,
                    focusHistoryId: c.focusHistoryId
                })), "address");
    }

    // Updates `model` in place to match `items` (same order), keeping delegates for unchanged
    // keys alive so their geometry animates instead of being recreated.
    function syncModel(model, items, key) {
        const wanted = new Set(items.map(item => item[key]));
        for (let i = model.count - 1; i >= 0; i--) {
            if (!wanted.has(model.get(i)[key])) {
                model.remove(i);
            }
        }

        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            let found = -1;
            for (let k = i; k < model.count; k++) {
                if (model.get(k)[key] === item[key]) {
                    found = k;
                    break;
                }
            }

            if (found === -1) {
                model.insert(i, item);
            } else {
                if (found !== i) {
                    model.move(found, i, 1);
                }
                model.set(i, item);
            }
        }
    }

    function computeLayout(workspaces) {
        const monitors = {};
        for (const m of HyprState.monitors) {
            monitors[m.id] = m;
        }

        const fallback = HyprState.monitors[0] ?? {
            id: -1,
            x: 0,
            y: 0,
            width: 1920,
            height: 1080,
            reserved: [0, 0, 0, 0]
        };

        const entries = workspaces.map(w => {
            const mon = monitors[w.monitorId] ?? fallback;
            const aspect = mon.width / Math.max(1, mon.height);
            const deskW = Math.min(maxDeskW, maxDeskH * aspect);
            return {
                wsId: w.id,
                name: w.name,
                mon,
                deskW,
                deskH: deskW / aspect
            };
        });

        // shrink everything uniformly if the row would not fit on this screen
        const fixed = 2 * pad + newCardW + cardSpacing * entries.length;
        const available = Math.max(160, width - 2 * edgeMargin - 30 - fixed);
        const total = entries.reduce((sum, e) => sum + e.deskW, 0);
        const shrink = total > available ? available / total : 1;

        let maxH = 0;
        for (const e of entries) {
            e.deskW *= shrink;
            e.deskH *= shrink;
            maxH = Math.max(maxH, e.deskH);
        }
        if (entries.length === 0) {
            maxH = maxDeskH * 0.6;
        }

        const byId = {};
        let x = pad;
        for (const e of entries) {
            e.x = x;
            e.y = pad + headerH + (maxH - e.deskH) / 2;
            e.scale = e.deskW / Math.max(1, e.mon.width);
            byId[e.wsId] = e;
            x += e.deskW + cardSpacing;
        }

        return {
            entries,
            byId,
            newCard: {
                x,
                y: pad + headerH,
                w: newCardW,
                h: maxH
            },
            width: x + newCardW + pad,
            height: pad + headerH + maxH + pad
        };
    }

    // ---- geometry helpers --------------------------------------------------------------------

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }

    function indexOf(address) {
        for (let i = 0; i < winModel.count; i++) {
            if (winModel.get(i).address === address) {
                return i;
            }
        }
        return -1;
    }

    function workspaceName(wsId) {
        for (let i = 0; i < wsModel.count; i++) {
            const ws = wsModel.get(i);
            if (ws.wsId === wsId) {
                return ws.name;
            }
        }
        return String(wsId);
    }

    function prettyName(cls) {
        if (!cls) {
            return "window";
        }
        const entry = DesktopEntries.heuristicLookup(cls);
        if (entry?.name) {
            return entry.name;
        }
        const last = cls.split(".").pop();
        return last.charAt(0).toUpperCase() + last.slice(1);
    }

    // global logical rect -> rect in the overview, clipped to its card's desk
    function windowRect(wsId, gx, gy, gw, gh) {
        const e = layout.byId[wsId];
        if (!e) {
            return null;
        }

        const m = e.mon;
        const x0 = clamp((gx - m.x) * e.scale, 0, e.deskW);
        const y0 = clamp((gy - m.y) * e.scale, 0, e.deskH);
        const x1 = clamp((gx + gw - m.x) * e.scale, 0, e.deskW);
        const y1 = clamp((gy + gh - m.y) * e.scale, 0, e.deskH);
        return {
            x: e.x + x0,
            y: e.y + y0,
            w: Math.max(3, x1 - x0),
            h: Math.max(3, y1 - y0)
        };
    }

    function contains(r, px, py, inset) {
        const ix = r.w * (inset ?? 0);
        const iy = r.h * (inset ?? 0);
        return px >= r.x + ix && px <= r.x + r.w - ix && py >= r.y + iy && py <= r.y + r.h - iy;
    }

    function tiledNeighbours(w) {
        const list = [];
        for (let i = 0; i < winModel.count; i++) {
            const o = winModel.get(i);
            if (o.wsId === w.wsId && !o.floating && !o.fullscreen) {
                list.push({
                    index: i,
                    address: o.address,
                    gx: o.gx,
                    gy: o.gy,
                    gw: o.gw,
                    gh: o.gh
                });
            }
        }
        return list;
    }

    readonly property real edgeTolerance: 40
    readonly property real minWindowSize: 80

    // which edges of a window can be dragged: every edge of a floating window, but only the
    // inner edges (ones that have a neighbour across them) of a tiled one
    function resizableEdges(w) {
        const edges = {
            l: false,
            r: false,
            t: false,
            b: false
        };
        if (w.fullscreen) {
            return edges;
        }
        if (w.floating) {
            return {
                l: true,
                r: true,
                t: true,
                b: true
            };
        }

        const tol = edgeTolerance;
        for (const o of tiledNeighbours(w)) {
            if (o.address === w.address) {
                continue;
            }
            const vOverlap = Math.min(o.gy + o.gh, w.gy + w.gh) - Math.max(o.gy, w.gy) > 0;
            const hOverlap = Math.min(o.gx + o.gw, w.gx + w.gw) - Math.max(o.gx, w.gx) > 0;
            if (vOverlap && Math.abs(o.gx - (w.gx + w.gw)) < tol) {
                edges.r = true;
            }
            if (vOverlap && Math.abs(o.gx + o.gw - w.gx) < tol) {
                edges.l = true;
            }
            if (hOverlap && Math.abs(o.gy - (w.gy + w.gh)) < tol) {
                edges.b = true;
            }
            if (hOverlap && Math.abs(o.gy + o.gh - w.gy) < tol) {
                edges.t = true;
            }
        }
        return edges;
    }

    // ---- hit testing -------------------------------------------------------------------------

    function hitTest(px, py, dragged) {
        const viaButton = anchorItem.workspaceAt ? anchorItem.workspaceAt(windowLayer, px, py) : null;
        if (viaButton) {
            if (viaButton.id === dragged.wsId) {
                return null;
            }
            return {
                type: "move",
                wsId: viaButton.id,
                name: String(viaButton.name),
                viaButton: true
            };
        }

        if (contains(layout.newCard, px, py)) {
            return {
                type: "new"
            };
        }

        for (const e of layout.entries) {
            const card = {
                x: e.x,
                y: e.y - headerH,
                w: e.deskW,
                h: e.deskH + headerH
            };
            if (!contains(card, px, py)) {
                continue;
            }

            // topmost window under the pointer: floating ones first (most recently focused first)
            let hit = null;
            let hitRect = null;
            let best = Infinity;
            for (let i = 0; i < winModel.count; i++) {
                const o = winModel.get(i);
                if (o.wsId !== e.wsId || o.address === dragged.address) {
                    continue;
                }
                const r = windowRect(o.wsId, o.gx, o.gy, o.gw, o.gh);
                if (!r || !contains(r, px, py)) {
                    continue;
                }
                const rank = (o.floating ? 0 : 1000) + o.focusHistoryId;
                if (rank < best) {
                    best = rank;
                    hit = o;
                    hitRect = r;
                }
            }

            const sameWorkspace = e.wsId === dragged.wsId;
            if (hit && !hit.floating && !hit.fullscreen && !dragged.floating) {
                // across workspaces only the middle of a window swaps; its rim still means "move"
                if (sameWorkspace || contains(hitRect, px, py, 0.22)) {
                    return {
                        type: "swap",
                        wsId: e.wsId,
                        address: hit.address,
                        cls: hit.cls
                    };
                }
            }

            if (sameWorkspace) {
                return dragged.floating ? {
                    type: "reposition",
                    wsId: e.wsId
                } : null;
            }

            return {
                type: "move",
                wsId: e.wsId,
                name: e.name
            };
        }

        return null;
    }

    function describeTarget(t) {
        if (!t) {
            return "";
        }
        switch (t.type) {
        case "swap":
            return `Swap with ${prettyName(t.cls)}`;
        case "move":
            return `Move to workspace ${t.name}`;
        case "new":
            return "Move to a new workspace";
        case "reposition":
            return "Move here";
        }
        return "";
    }

    // ---- dragging windows ----------------------------------------------------------------------

    function beginDrag(w, px, py) {
        closeTimer.stop();
        w.held = true;
        dragInfo = {
            address: w.address,
            wsId: w.wsId,
            floating: w.floating,
            offX: px - w.vx,
            offY: py - w.vy,
            origin: {
                x: w.vx,
                y: w.vy,
                w: w.vw,
                h: w.vh
            }
        };
        pointer = Qt.point(px, py);
    }

    function updateDrag(w, px, py) {
        w.vx = px - dragInfo.offX;
        w.vy = py - dragInfo.offY;
        pointer = Qt.point(px, py);
        dropTarget = hitTest(px, py, w);
    }

    function endDrag(w, px, py, cancelled) {
        const target = cancelled ? null : hitTest(px, py, w);
        if (target) {
            commitDrop(w, target);
        }

        dragInfo = null;
        dropTarget = null;
        w.held = false;
        w.rebind(); // animates from wherever it was dropped to its (new) slot
        finishInteraction();
    }

    function setGeometry(index, values) {
        if (index >= 0) {
            winModel.set(index, values);
        }
    }

    // drop position of `w` mapped into workspace `e`, in global coords, kept on that monitor
    function dropGeometry(w, e, keepRealSize) {
        const m = e.mon;
        const gw = keepRealSize ? w.gw : w.vw / e.scale;
        const gh = keepRealSize ? w.gh : w.vh / e.scale;
        const gx = m.x + (w.vx - e.x) / e.scale;
        const gy = m.y + (w.vy - e.y) / e.scale;
        return {
            gx: clamp(gx, m.x, m.x + Math.max(0, m.width - Math.min(gw, m.width))),
            gy: clamp(gy, m.y, m.y + Math.max(0, m.height - Math.min(gh, m.height))),
            gw: Math.min(gw, m.width),
            gh: Math.min(gh, m.height)
        };
    }

    function commitDrop(w, t) {
        const index = indexOf(w.address);
        let epoch = 0;

        if (t.type === "swap") {
            const other = indexOf(t.address);
            const a = winModel.get(index);
            const b = winModel.get(other);
            const ga = {
                wsId: a.wsId,
                gx: a.gx,
                gy: a.gy,
                gw: a.gw,
                gh: a.gh
            };
            const gb = {
                wsId: b.wsId,
                gx: b.gx,
                gy: b.gy,
                gw: b.gw,
                gh: b.gh
            };
            // optimistic: trade places now, hyprland's answer will settle the details
            setGeometry(index, gb);
            setGeometry(other, ga);
            epoch = HyprState.swapWindows(w.address, t.address);
        } else if (t.type === "move" || t.type === "reposition") {
            const e = layout.byId[t.wsId];
            if (!e) {
                return;
            }

            let geo;
            if (t.viaButton) {
                // dropped on the taskbar: park it in the middle of that desk until hyprland answers
                const m = e.mon;
                geo = {
                    gx: m.x + m.width * 0.25,
                    gy: m.y + m.height * 0.25,
                    gw: m.width * 0.5,
                    gh: m.height * 0.5
                };
            } else {
                geo = dropGeometry(w, e, w.floating);
            }

            setGeometry(index, Object.assign({
                wsId: t.wsId
            }, geo));

            const floatingPos = w.floating && !t.viaButton ? {
                x: geo.gx,
                y: geo.gy
            } : null;

            if (t.type === "move") {
                epoch = HyprState.moveToWorkspace(w.address, HyprState.workspaceSelector(t.wsId, workspaceName(t.wsId)), floatingPos);
            } else {
                epoch = HyprState.moveFloating(w.address, geo.gx, geo.gy);
            }
        } else if (t.type === "new") {
            epoch = HyprState.moveToWorkspace(w.address, "emptym", null);
        }

        requiredEpoch = Math.max(requiredEpoch, epoch);
    }

    // ---- resizing windows ----------------------------------------------------------------------

    function beginResize(w, edge, px, py) {
        closeTimer.stop();
        const e = layout.byId[w.wsId];
        if (!e) {
            return;
        }

        const hEdge = edge.includes("l") ? "l" : edge.includes("r") ? "r" : "";
        const vEdge = edge.includes("t") ? "t" : edge.includes("b") ? "b" : "";
        const links = [];

        if (w.floating) {
            links.push({
                index: indexOf(w.address),
                address: w.address,
                orig: {
                    gx: w.gx,
                    gy: w.gy,
                    gw: w.gw,
                    gh: w.gh
                },
                l: hEdge === "l",
                r: hEdge === "r",
                t: vEdge === "t",
                b: vEdge === "b"
            });
        } else {
            // every tiled edge lying on the dragged divider moves with it, which is what
            // hyprland will do once the split ratio changes
            const tol = edgeTolerance;
            const lineX = hEdge === "l" ? w.gx : hEdge === "r" ? w.gx + w.gw : null;
            const lineY = vEdge === "t" ? w.gy : vEdge === "b" ? w.gy + w.gh : null;

            for (const o of tiledNeighbours(w)) {
                const link = {
                    index: o.index,
                    address: o.address,
                    orig: {
                        gx: o.gx,
                        gy: o.gy,
                        gw: o.gw,
                        gh: o.gh
                    },
                    l: lineX !== null && Math.abs(o.gx - lineX) < tol,
                    r: lineX !== null && Math.abs(o.gx + o.gw - lineX) < tol,
                    t: lineY !== null && Math.abs(o.gy - lineY) < tol,
                    b: lineY !== null && Math.abs(o.gy + o.gh - lineY) < tol
                };
                if (link.l || link.r || link.t || link.b) {
                    links.push(link);
                }
            }
        }

        resizeInfo = {
            address: w.address,
            floating: w.floating,
            edge,
            hEdge,
            vEdge,
            scale: e.scale,
            startX: px,
            startY: py,
            dx: 0,
            dy: 0,
            links
        };
        pointer = Qt.point(px, py);
    }

    function updateResize(px, py) {
        const r = resizeInfo;
        if (!r) {
            return;
        }

        let dx = r.hEdge ? (px - r.startX) / r.scale : 0;
        let dy = r.vEdge ? (py - r.startY) / r.scale : 0;

        for (const l of r.links) {
            if (l.r) {
                dx = Math.max(dx, minWindowSize - l.orig.gw);
            }
            if (l.l) {
                dx = Math.min(dx, l.orig.gw - minWindowSize);
            }
            if (l.b) {
                dy = Math.max(dy, minWindowSize - l.orig.gh);
            }
            if (l.t) {
                dy = Math.min(dy, l.orig.gh - minWindowSize);
            }
        }

        for (const l of r.links) {
            let gx = l.orig.gx, gy = l.orig.gy, gw = l.orig.gw, gh = l.orig.gh;
            if (l.l) {
                gx += dx;
                gw -= dx;
            }
            if (l.r) {
                gw += dx;
            }
            if (l.t) {
                gy += dy;
                gh -= dy;
            }
            if (l.b) {
                gh += dy;
            }
            winModel.set(l.index, {
                gx,
                gy,
                gw,
                gh
            });
        }

        r.dx = dx;
        r.dy = dy;
        pointer = Qt.point(px, py);
    }

    // The window whose split owns a divider is (almost always) the one with the longest edge
    // along it; ties go to the window being dragged.
    function dividerOwner(r, axis) {
        let best = null;
        let bestLength = -1;
        for (const l of r.links) {
            const onDivider = axis === "x" ? (l.l || l.r) : (l.t || l.b);
            if (!onDivider) {
                continue;
            }
            const length = axis === "x" ? l.orig.gh : l.orig.gw;
            const bonus = l.address === r.address ? 1 : 0;
            if (length + bonus > bestLength) {
                bestLength = length + bonus;
                best = l.address;
            }
        }
        return best ?? r.address;
    }

    function endResize(cancelled) {
        const r = resizeInfo;
        resizeInfo = null;
        if (!r) {
            finishInteraction();
            return;
        }

        const moved = Math.abs(r.dx) >= 1 || Math.abs(r.dy) >= 1;

        if (cancelled || !moved) {
            for (const l of r.links) {
                winModel.set(l.index, l.orig);
            }
        } else if (r.floating) {
            const s = winModel.get(r.links[0].index);
            requiredEpoch = Math.max(requiredEpoch, HyprState.setFloatingGeometry(r.address, s.gx, s.gy, s.gw, s.gh));
        } else {
            const commands = [];
            if (Math.abs(r.dx) >= 1) {
                commands.push({
                    address: dividerOwner(r, "x"),
                    dx: r.dx,
                    dy: 0
                });
            }
            if (Math.abs(r.dy) >= 1) {
                commands.push({
                    address: dividerOwner(r, "y"),
                    dx: 0,
                    dy: r.dy
                });
            }
            requiredEpoch = Math.max(requiredEpoch, HyprState.moveDividers(commands));
        }

        finishInteraction();
    }

    function finishInteraction() {
        if (syncPending && HyprState.dataEpoch >= requiredEpoch) {
            sync();
        }
        scheduleClose();
    }

    // ---- simple actions ------------------------------------------------------------------------

    function focusWindow(address) {
        HyprState.focusWindow(address);
        open = false;
    }

    function closeWindow(address) {
        HyprState.closeWindow(address);
    }

    function activateWorkspace(wsId) {
        HyprState.focusWorkspace(HyprState.workspaceSelector(wsId, workspaceName(wsId)));
    }

    function createWorkspace() {
        HyprState.focusWorkspace("emptym");
    }

    // ---- view ----------------------------------------------------------------------------------

    readonly property real anchorCenterX: {
        anchorItem.x;
        anchorItem.width;
        width;
        return anchorItem.mapToItem(root, anchorItem.width / 2, 0).x;
    }

    Item {
        id: maskProxy
        x: frame.x
        y: frame.y
        width: root.open ? frame.width : 0
        height: root.open ? frame.height : 0
    }

    Aeroframe {
        id: frame

        width: root.layout.width + frameWidth * 2 + 2
        height: root.layout.height + topFrameWidth + frameWidth + 2
        x: root.clamp(root.anchorCenterX - width / 2, root.edgeMargin, root.width - width - root.edgeMargin)
        anchors.bottom: parent.bottom

        clipContent: false
        contentColor: Qt.rgba(0.04, 0.08, 0.14, 0.34)
        frameOpacity: root.open ? 1 : 0
        visible: frameOpacity > 0.01
        scale: root.open ? 1 : 0.86
        transformOrigin: Item.Bottom

        Behavior on frameOpacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: content
            width: root.layout.width
            height: root.layout.height

            Repeater {
                model: wsModel

                delegate: OverviewCard {
                    overview: root
                }
            }

            // "+" slot: click for a fresh workspace, drop a window on it to send it to one
            Item {
                id: newSlot

                readonly property bool dropHot: root.dropTarget?.type === "new"
                property real hoverT: newSlotMouse.containsMouse || dropHot ? 1 : 0

                x: root.layout.newCard.x
                y: root.layout.newCard.y
                width: root.layout.newCard.w
                height: root.layout.newCard.h

                Behavior on x {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on hoverT {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.05 + 0.12 * newSlot.hoverT)
                    border.width: 1
                    border.color: newSlot.dropHot ? "#9fe8ff" : Qt.rgba(1, 1, 1, 0.25 + 0.3 * newSlot.hoverT)
                }

                Win7Hover {
                    radius: 4
                    opacity: newSlot.hoverT
                    pressedT: newSlotMouse.pressed ? 1 : 0
                }

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "white"
                    opacity: 0.6 + 0.4 * newSlot.hoverT
                    font.pixelSize: 22
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.5)
                }

                MouseArea {
                    id: newSlotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.createWorkspace()
                }
            }

            // where the dragged window came from
            Rectangle {
                visible: root.dragInfo !== null
                x: root.dragInfo?.origin.x ?? 0
                y: root.dragInfo?.origin.y ?? 0
                width: root.dragInfo?.origin.w ?? 0
                height: root.dragInfo?.origin.h ?? 0
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.07)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.35)
            }

            Item {
                id: windowLayer
                anchors.fill: parent

                Repeater {
                    model: winModel

                    delegate: OverviewWindow {
                        overview: root
                    }
                }
            }

            AeroTooltip {
                z: 2000
                x: root.pointer.x + 14
                y: root.pointer.y + 16
                text: root.describeTarget(root.dropTarget)
                shown: root.dragInfo !== null && root.dropTarget !== null
            }
        }
    }
}
