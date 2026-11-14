pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../components"
import "../../../services"
import "../../../utils/constants.js" as Constants

Item {
    id: root

    required property Item anchorItem

    readonly property alias maskItem: maskProxy
    readonly property alias windowLayerItem: windowLayer
    property bool open: false

    readonly property real maxDeskW: 216
    readonly property real maxDeskH: 128
    readonly property real cardSpacing: 14
    readonly property real headerH: 20
    readonly property real pad: 10
    readonly property real newCardW: 34
    readonly property real edgeMargin: 10

    readonly property string focusedAddress: HyprState.focusedAddress
    readonly property var activeWorkspaceIds: HyprState.monitors.map(m => m.activeWorkspaceId)
    readonly property int focusedWorkspaceId: HyprState.monitors.find(m => m.focused)?.activeWorkspaceId ?? Constants.NO_WORKSPACE
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

    property var dragInfo: null
    property var resizeInfo: null
    property var dropTarget: null
    property point pointer: Qt.point(0, 0)
    property int hoveredWorkspaceId: Constants.NO_WORKSPACE
    readonly property bool resizing: resizeInfo !== null
    readonly property bool interacting: dragInfo !== null || resizeInfo !== null
    property bool syncPending: false
    // older snapshots predate our last dispatch and would undo optimistic updates
    property int requiredEpoch: 0

    readonly property int highlightedWorkspaceId: dropTarget ? (dropTarget.wsId ?? Constants.NO_WORKSPACE) : hoveredWorkspaceId

    implicitHeight: frame.height

    ListModel {
        id: wsModel
    }

    ListModel {
        id: winModel
    }

    readonly property bool triggerHovered: anchorItem.hovered ?? false

    readonly property bool keepOpen: triggerHovered || frame.hovered || interacting

    onTriggerHoveredChanged: {
        if (!triggerHovered) {
            openTimer.stop();
        } else if (!open) {
            openTimer.restart();
            HyprState.refresh();
        }
    }

    onOpenChanged: {
        if (open) {
            HyprState.retain(true);
        } else {
            HyprState.release(true);
            hoveredWorkspaceId = Constants.NO_WORKSPACE;
        }
    }

    Component.onDestruction: {
        if (open) {
            HyprState.release(true);
        }
    }

    Connections {
        target: root.anchorItem

        // a click means "go there", so restart the hover delay rather than open
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
        running: root.open && !root.keepOpen
        onTriggered: root.open = false
    }

    Binding {
        target: root.anchorItem
        property: "highlightWorkspaceId"
        value: root.open ? root.highlightedWorkspaceId : Constants.NO_WORKSPACE
    }

    readonly property bool tracking: open || triggerHovered || frame.visible

    function syncWhenSettled() {
        if (interacting || HyprState.dataEpoch < requiredEpoch) {
            syncPending = true;
        } else {
            sync();
        }
    }

    onTrackingChanged: {
        if (tracking && HyprState.loaded) {
            syncWhenSettled();
        }
    }

    Connections {
        target: HyprState
        enabled: root.tracking

        function onUpdated() {
            root.syncWhenSettled();
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

        // before the models, so no delegate sees a workspace the layout lacks
        layout = computeLayout(workspaces);
        windowCounts = counts;

        syncModel(wsModel, workspaces.map(w => ({
                    wsId: w.id,
                    name: w.name
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

    // in place: delegates for unchanged keys survive, so their geometry animates
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

    // Hyprland global logical px -> overview px, clipped to the card's desk
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

    function rectOf(o) {
        return {
            gx: o.gx,
            gy: o.gy,
            gw: o.gw,
            gh: o.gh
        };
    }

    function tiledWindowsOf(w) {
        const list = [];
        for (let i = 0; i < winModel.count; i++) {
            const o = winModel.get(i);
            if (o.wsId === w.wsId && !o.floating && !o.fullscreen) {
                list.push(Object.assign({
                    index: i,
                    address: o.address
                }, rectOf(o)));
            }
        }
        return list;
    }

    readonly property real edgeTolerance: 40
    readonly property real minWindowSize: 80

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
        for (const o of tiledWindowsOf(w)) {
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

    function hitTest(px, py, dragged) {
        const buttonWs = anchorItem.workspaceAt ? anchorItem.workspaceAt(windowLayer, px, py) : null;
        if (buttonWs) {
            const key = HyprState.keyOf(buttonWs);
            if (key === dragged.wsId || !layout.byId[key]) {
                return null;
            }
            return {
                type: "move",
                wsId: key,
                name: String(buttonWs.name),
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

            // floating first, then most recently focused (focusHistoryId 0 = latest)
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
            // Hyprland refuses to swap fullscreen windows
            if (hit && !hit.floating && !hit.fullscreen && !dragged.floating && !dragged.fullscreen) {
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
                return dragged.floating && !dragged.fullscreen ? {
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

    function beginDrag(w, px, py) {
        dragInfo = {
            address: w.address,
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
        // a new object on every move would re-run every window's and card's bindings
        const target = hitTest(px, py, w);
        if (JSON.stringify(target) !== JSON.stringify(dropTarget)) {
            dropTarget = target;
        }
    }

    function endDrag(w, px, py, cancelled) {
        const target = cancelled ? null : hitTest(px, py, w);
        if (target) {
            commitDrop(w, target);
        }

        dragInfo = null;
        dropTarget = null;
        w.rebind();
        finishInteraction();
    }

    function updateWindow(index, values) {
        if (index >= 0) {
            winModel.set(index, values);
        }
    }

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

    // a floating window keeps its size and relative spot on another monitor, kept on screen
    function carriedGeometry(w, m) {
        const from = layout.byId[w.wsId]?.mon ?? m;
        const gw = Math.min(w.gw, m.width);
        const gh = Math.min(w.gh, m.height);
        return {
            gx: m.x + clamp((w.gx - from.x) / from.width * m.width, 0, m.width - gw),
            gy: m.y + clamp((w.gy - from.y) / from.height * m.height, 0, m.height - gh),
            gw,
            gh
        };
    }

    function commitDrop(w, t) {
        const index = indexOf(w.address);
        let epoch = 0;

        if (t.type === "swap") {
            const other = indexOf(t.address);
            const a = winModel.get(index);
            const b = winModel.get(other);
            const ga = Object.assign({
                wsId: a.wsId
            }, rectOf(a));
            const gb = Object.assign({
                wsId: b.wsId
            }, rectOf(b));
            updateWindow(index, gb);
            updateWindow(other, ga);
            epoch = HyprState.swapWindows(w.address, t.address);
        } else if (t.type === "move" || t.type === "reposition") {
            const e = layout.byId[t.wsId];
            if (!e) {
                return;
            }

            let geo;
            if (t.viaButton && w.floating) {
                geo = carriedGeometry(w, e.mon);
            } else if (t.viaButton) {
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

            updateWindow(index, Object.assign({
                wsId: t.wsId
            }, geo));

            if (t.type === "move") {
                const floatingPos = w.floating && !w.fullscreen ? {
                    x: geo.gx,
                    y: geo.gy
                } : null;
                epoch = HyprState.moveToWorkspace(w.address, HyprState.workspaceSelector(t.wsId), floatingPos);
            } else {
                epoch = HyprState.moveFloating(w.address, geo.gx, geo.gy);
            }
        } else if (t.type === "new") {
            epoch = HyprState.moveToWorkspace(w.address, "emptym", null);
        }

        requiredEpoch = Math.max(requiredEpoch, epoch);
    }

    function beginResize(w, edge, px, py) {
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
                orig: rectOf(w),
                l: hEdge === "l",
                r: hEdge === "r",
                t: vEdge === "t",
                b: vEdge === "b"
            });
        } else {
            // hyprland moves every edge on this divider, but not aligned edges past a gap
            const tol = edgeTolerance;
            const lineX = hEdge === "l" ? w.gx : hEdge === "r" ? w.gx + w.gw : null;
            const lineY = vEdge === "t" ? w.gy : vEdge === "b" ? w.gy + w.gh : null;

            const touching = tiledWindowsOf(w).map(o => ({
                        o,
                        l: lineX !== null && Math.abs(o.gx - lineX) < tol,
                        r: lineX !== null && Math.abs(o.gx + o.gw - lineX) < tol,
                        t: lineY !== null && Math.abs(o.gy - lineY) < tol,
                        b: lineY !== null && Math.abs(o.gy + o.gh - lineY) < tol
                    }));
            const onX = chained(touching.filter(c => c.l || c.r), c => [c.o.gy, c.o.gy + c.o.gh], [w.gy, w.gy + w.gh]);
            const onY = chained(touching.filter(c => c.t || c.b), c => [c.o.gx, c.o.gx + c.o.gw], [w.gx, w.gx + w.gw]);

            for (const c of touching) {
                const link = {
                    index: c.o.index,
                    address: c.o.address,
                    orig: rectOf(c.o),
                    l: c.l && onX.includes(c),
                    r: c.r && onX.includes(c),
                    t: c.t && onY.includes(c),
                    b: c.b && onY.includes(c)
                };
                if (link.l || link.r || link.t || link.b) {
                    links.push(link);
                }
            }
        }

        const tiled = w.floating ? [] : tiledWindowsOf(w);
        resizeInfo = {
            address: w.address,
            floating: w.floating,
            mon: e.mon,
            layoutName: HyprState.workspaces.find(ws => ws.id === w.wsId)?.layout ?? "",
            bounds: {
                x0: Math.min(...tiled.map(o => o.gx)),
                x1: Math.max(...tiled.map(o => o.gx + o.gw)),
                y0: Math.min(...tiled.map(o => o.gy)),
                y1: Math.max(...tiled.map(o => o.gy + o.gh))
            },
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
    }

    function chained(candidates, spanOf, start) {
        let lo = start[0], hi = start[1];
        const chain = [];
        let grew = true;
        while (grew) {
            grew = false;
            for (const c of candidates) {
                const span = spanOf(c);
                if (!chain.includes(c) && Math.min(span[1], hi) - Math.max(span[0], lo) > 0) {
                    chain.push(c);
                    lo = Math.min(lo, span[0]);
                    hi = Math.max(hi, span[1]);
                    grew = true;
                }
            }
        }
        return chain;
    }

    function updateResize(px, py) {
        const r = resizeInfo;
        if (!r) {
            return;
        }

        let dx = r.hEdge ? (px - r.startX) / r.scale : 0;
        let dy = r.vEdge ? (py - r.startY) / r.scale : 0;

        if (r.floating) {
            const l = r.links[0], m = r.mon;
            if (l.r) {
                dx = Math.min(dx, Math.max(0, m.x + m.width - l.orig.gx - l.orig.gw));
            }
            if (l.l) {
                dx = Math.max(dx, Math.min(0, m.x - l.orig.gx));
            }
            if (l.b) {
                dy = Math.min(dy, Math.max(0, m.y + m.height - l.orig.gy - l.orig.gh));
            }
            if (l.t) {
                dy = Math.max(dy, Math.min(0, m.y - l.orig.gy));
            }
        }

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
    }

    // a window reaching the far side of the workspace has no other divider on this axis, so a
    // resize can only move this one; otherwise the longest edge usually owns the split
    function dividerOwner(r, axis) {
        const tol = edgeTolerance, b = r.bounds;
        const onDivider = r.links.filter(l => axis === "x" ? (l.l || l.r) : (l.t || l.b));
        const before = l => axis === "x" ? l.r : l.b;

        // master grows the window it's given and shrinks the ones after it
        if (r.layoutName.includes("master")) {
            const owner = onDivider.find(l => l.address === r.address && before(l)) ?? onDivider.find(before);
            if (owner) {
                return owner.address;
            }
        }

        const outer = onDivider.filter(l => {
            if (axis === "x") {
                return l.r ? Math.abs(l.orig.gx - b.x0) < tol : Math.abs(l.orig.gx + l.orig.gw - b.x1) < tol;
            }
            return l.b ? Math.abs(l.orig.gy - b.y0) < tol : Math.abs(l.orig.gy + l.orig.gh - b.y1) < tol;
        });
        if (outer.length > 0) {
            return (outer.find(before) ?? outer[0]).address;
        }

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
    }

    function focusWindow(address) {
        HyprState.focusWindow(address);
        open = false;
    }

    function closeWindow(address) {
        HyprState.closeWindow(address);
    }

    function activateWorkspace(wsId) {
        HyprState.focusWorkspace(HyprState.workspaceSelector(wsId));
    }

    function createWorkspace() {
        HyprState.focusWorkspace("emptym");
    }

    // mapToItem() isn't tracked by bindings: read its inputs to re-evaluate
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
