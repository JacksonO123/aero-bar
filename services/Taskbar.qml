pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels.values

    function appIdOf(t) {
        return t?.wayland?.appId || t?.lastIpcObject?.class || "";
    }

    function idsOf(app) {
        const ids = (app.appIds ?? []).map(s => s.toLowerCase());
        if (ids.length === 0 && app.cmd?.length) {
            ids.push(String(app.cmd[0]).split("/").pop().toLowerCase());
        }
        return ids;
    }

    function windowsFor(app) {
        const ids = idsOf(app);
        // no wayland handle: hidden X11 windows and popups, not real windows
        return toplevels.filter(t => t.wayland && ids.includes(appIdOf(t).toLowerCase()));
    }

    // Quickshell addresses lack the "0x" prefix hyprctl and dispatchers use
    function hyprAddress(t) {
        return t?.address ? "0x" + t.address : "";
    }

    function sameAddress(a, b) {
        const na = normalizeAddress(a);
        return na !== "" && na === normalizeAddress(b);
    }

    function normalizeAddress(v) {
        return String(v ?? "").toLowerCase().replace(/^0x/, "").replace(/^0+/, "");
    }

    // reading applications makes bindings re-evaluate when entries reload
    function entryById(id) {
        DesktopEntries.applications.values;
        return lookupEntry(id);
    }

    function lookupEntry(id) {
        return id ? DesktopEntries.heuristicLookup(id) : null;
    }

    function entryFor(app) {
        DesktopEntries.applications.values;
        for (const id of idsOf(app)) {
            const e = lookupEntry(id);
            if (e) {
                return e;
            }
        }
        return null;
    }
}
