pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Which open windows belong to which pinned taskbar app (see Apps.appIds), from Hyprland's
// toplevel list (event driven, no polling).
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

    // the app's windows, in Hyprland's order
    function windowsFor(app) {
        const ids = idsOf(app);
        return toplevels.filter(t => ids.includes(appIdOf(t).toLowerCase()));
    }

    // "0x" + hex, as hyprctl and dispatchers write window addresses
    function hyprAddress(t) {
        return t?.address ? "0x" + t.address : "";
    }

    function sameAddress(a, b) {
        const norm = v => String(v ?? "").toLowerCase().replace(/^0x/, "").replace(/^0+/, "");
        return norm(a) !== "" && norm(a) === norm(b);
    }

    function entryFor(app) {
        DesktopEntries.applications.values;
        for (const id of idsOf(app)) {
            const e = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
            if (e) {
                return e;
            }
        }
        return null;
    }
}
