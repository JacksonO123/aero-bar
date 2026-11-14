pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../utils/constants.js" as Constants

// stop mako / dunst / swaync first; qs ipc call notifications toggleDnd|clear
Singleton {
    id: root

    readonly property alias server: server
    readonly property var list: server.trackedNotifications.values.filter(n => n !== null)
    readonly property int count: list.length

    property var unreadIds: []
    readonly property int unread: unreadIds.length
    property int panesOpen: 0
    readonly property bool centerOpen: panesOpen > 0

    readonly property bool doNotDisturb: settings?.doNotDisturb ?? false

    // the server doesn't record arrival times
    property var times: ({})

    readonly property alias popups: popupModel

    // kept here as every screen has a copy of each balloon; nothing binds to it
    property var deadlines: ({})

    onCenterOpenChanged: {
        if (centerOpen) {
            unreadIds = [];
            clearPopups();
        }
    }

    function find(id) {
        return list.find(n => n.id === id) ?? null;
    }

    function timeOf(n) {
        return n ? (times[n.id] ?? null) : null;
    }

    function setDoNotDisturb(on) {
        settings.doNotDisturb = on;
        if (on) {
            clearPopups();
        }
    }

    function dismiss(n) {
        if (n) {
            dropPopup(n.id);
            n.dismiss();
        }
    }

    function clearAll() {
        clearPopups();
        for (const n of list.slice()) {
            n.dismiss();
        }
        unreadIds = [];
    }

    function extraActions(n) {
        return (n?.actions ?? []).filter(a => a.identifier !== "default");
    }

    function defaultAction(n) {
        return n?.actions?.find(a => a.identifier === "default") ?? null;
    }

    function activate(n) {
        const action = defaultAction(n);
        if (action) {
            action.invoke();
        } else {
            dismiss(n);
        }
    }

    function dropPopup(id) {
        delete deadlines[id];
        for (let i = popupModel.count - 1; i >= 0; i--) {
            if (popupModel.get(i).nid === id) {
                popupModel.remove(i);
            }
        }
    }

    function clearPopups() {
        const shown = [];
        for (let i = 0; i < popupModel.count; i++) {
            shown.push(popupModel.get(i).nid);
        }
        deadlines = {};
        popupModel.clear();
        shown.map(find).filter(n => n?.transient).forEach(n => n.expire());
    }

    function hasPopup(id) {
        for (let i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).nid === id) {
                return true;
            }
        }
        return false;
    }

    // takes n, not an id: a new one isn't in list until its handler returns
    function countDown(n) {
        // a timeout of 0 means never expire
        if (n && n.urgency !== NotificationUrgency.Critical && n.expireTimeout !== 0) {
            // expireTimeout is in ms, despite the docs saying seconds
            deadlines[n.id] = Date.now() + (n.expireTimeout > 0 ? n.expireTimeout : Constants.NOTIFICATION_TIMEOUT);
        }
    }

    function holdPopup(id) {
        delete deadlines[id];
    }

    function expirePopups() {
        const now = Date.now();
        for (const key of Object.keys(deadlines)) {
            if (deadlines[key] > now) {
                continue;
            }
            const id = Number(key);
            const n = find(id);
            if (n?.transient) {
                n.expire();
            }
            dropPopup(id);
        }
    }

    // times[id] must exist before tracked = true creates the rows that read it
    function track(n) {
        const id = n.id;
        times[id] = new Date();
        n.closed.connect(() => {
            delete root.times[id];
            root.unreadIds = root.unreadIds.filter(u => u !== id);
            root.dropPopup(id);
        });
        // replaces_id updates it in place, with no new notification signal
        n.summaryChanged.connect(() => root.replaced(n));
        n.bodyChanged.connect(() => root.replaced(n));
        n.tracked = true;
    }

    function receive(n) {
        track(n);

        // carried over a reload (keepOnReload): already announced
        if (!n.lastGeneration) {
            announce(n);
        }
    }

    // summary and body both change on replace: announce once, after both
    property var replacing: []

    function replaced(n) {
        if (replacing.includes(n)) {
            return;
        }
        replacing.push(n);
        Qt.callLater(() => {
            root.replacing = root.replacing.filter(r => r !== n);
            if (root.list.includes(n)) {
                root.announce(n);
            }
        });
    }

    function announce(n) {
        const urgent = n.urgency === NotificationUrgency.Critical;
        const balloon = !centerOpen && (!doNotDisturb || urgent);

        // transient ones only live as balloons; still being announced, so expire() can't close
        // them: drop the bookkeeping here
        if (n.transient && !balloon) {
            delete times[n.id];
            n.expire();
            return;
        }

        if (centerOpen) {
            return;
        }

        if (!unreadIds.includes(n.id)) {
            unreadIds = unreadIds.concat([n.id]);
        }

        if (!balloon) {
            return;
        }

        // a replacement (progress updates) keeps its balloon, and a hovered one stays held
        if (!hasPopup(n.id)) {
            popupModel.append({
                nid: n.id
            });
            countDown(n);
        } else if (n.id in deadlines) {
            delete deadlines[n.id];
            countDown(n);
        }

        while (popupModel.count > Constants.MAX_NOTIFICATION_POPUPS) {
            const oldest = find(popupModel.get(0).nid);
            dropPopup(popupModel.get(0).nid);
            if (oldest?.transient) {
                oldest.expire();
            }
        }
    }

    ListModel {
        id: popupModel
    }

    Timer {
        interval: 200
        repeat: true
        running: popupModel.count > 0
        onTriggered: root.expirePopups()
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => root.receive(n)
    }

    FileView {
        path: Quickshell.statePath("notifications.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: settings
            property bool doNotDisturb: false
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            root.setDoNotDisturb(!root.doNotDisturb);
        }

        function clear(): void {
            root.clearAll();
        }
    }
}
