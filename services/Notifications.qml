pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../utils/constants.js" as Constants

// The shell's notification server. New notifications pop up as Win7 balloons above the tray
// and are kept in the Action Center (the flag in the taskbar) until dismissed.
//
// Only one notification daemon can run: stop mako / dunst / swaync before using this.
//   qs ipc call notifications toggleDnd
//   qs ipc call notifications clear
Singleton {
    id: root

    readonly property alias server: server
    // newest last
    readonly property var list: server.trackedNotifications.values.filter(n => n !== null)
    readonly property int count: list.length

    // ids that arrived while the Action Center was closed and are still around
    property var unreadIds: []
    readonly property int unread: unreadIds.length
    // Action Center panes currently open (one per screen at most)
    property int panesOpen: 0
    readonly property bool centerOpen: panesOpen > 0

    readonly property bool doNotDisturb: settings?.doNotDisturb ?? false

    // arrival time per notification id (the server doesn't keep one)
    property var times: ({})

    // ids of the balloons on screen, oldest first
    readonly property alias popups: popupModel

    // when each balloon times out (ms since the epoch), by notification id; a hovered or critical
    // one has none. Kept here rather than in the balloons: every screen has a copy of each, and
    // the countdown must carry on when focus moves to another screen. Changed in place (nothing
    // binds to it).
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

    // the buttons to show: every action but the default one (that's clicking the notification)
    function extraActions(n) {
        return (n?.actions ?? []).filter(a => a.identifier !== "default");
    }

    function defaultAction(n) {
        return n?.actions?.find(a => a.identifier === "default") ?? null;
    }

    // clicking a notification: run its default action if it has one, otherwise just put it away
    function activate(n) {
        const action = defaultAction(n);
        if (action) {
            action.invoke();
        } else {
            dismiss(n);
        }
    }

    // ---- balloons ------------------------------------------------------------------------------

    function dropPopup(id) {
        delete deadlines[id];
        for (let i = popupModel.count - 1; i >= 0; i--) {
            if (popupModel.get(i).nid === id) {
                popupModel.remove(i);
            }
        }
    }

    function clearPopups() {
        deadlines = {};
        popupModel.clear();
    }

    // (re)start a balloon's countdown: when it pops up, and when the pointer leaves it. Takes the
    // notification itself: a new one isn't in `list` until its `notification` handler is done.
    function countDown(n) {
        if (n && n.urgency !== NotificationUrgency.Critical) {
            // the app's timeout comes through as sent, in ms (the docs' "seconds" is wrong)
            deadlines[n.id] = Date.now() + (n.expireTimeout > 0 ? n.expireTimeout : Constants.NOTIFICATION_TIMEOUT);
        }
    }

    // a hovered balloon waits
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

    // Keep it (in the server's list) and note when it arrived. `times` is changed in place: the
    // time must exist before `tracked` creates the rows that read it, and nothing on screen
    // reacts to an entry going away.
    function track(n) {
        const id = n.id;
        times[id] = new Date();
        n.closed.connect(() => {
            delete root.times[id];
            root.unreadIds = root.unreadIds.filter(u => u !== id);
            root.dropPopup(id);
        });
        // sent again with its id (`replaces_id`): the server updates it in place, with no new
        // `notification` signal
        n.summaryChanged.connect(() => root.replaced(n));
        n.bodyChanged.connect(() => root.replaced(n));
        n.tracked = true;
    }

    function receive(n) {
        track(n);

        // carried over from before a shell reload (keepOnReload): kept, but not announced again
        if (!n.lastGeneration) {
            announce(n);
        }
    }

    // a replacement can change the summary and the body: announce it once, after both
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

    // count it as unread and pop up its balloon (in its old one's place, if it's a replacement).
    // Nothing pops up over an open Action Center, which shows it straight away.
    function announce(n) {
        if (centerOpen) {
            return;
        }

        if (!unreadIds.includes(n.id)) {
            unreadIds = unreadIds.concat([n.id]);
        }

        const urgent = n.urgency === NotificationUrgency.Critical;
        if (doNotDisturb && !urgent) {
            return;
        }

        dropPopup(n.id);
        popupModel.append({
            nid: n.id
        });
        countDown(n);
        while (popupModel.count > Constants.MAX_NOTIFICATION_POPUPS) {
            dropPopup(popupModel.get(0).nid);
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
