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

    // arrived while the Action Center was closed
    property int unread: 0
    // Action Center panes currently open (one per screen at most)
    property int centersOpen: 0
    readonly property bool centerOpen: centersOpen > 0

    readonly property bool doNotDisturb: settings.doNotDisturb

    // arrival time per notification id (the server doesn't keep one)
    property var times: ({})

    // ids of the balloons on screen, oldest first
    readonly property alias popups: popupModel

    onCenterOpenChanged: {
        if (centerOpen) {
            unread = 0;
            popupModel.clear();
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
            popupModel.clear();
        }
    }

    function dismiss(n) {
        if (n) {
            dropPopup(n.id);
            n.dismiss();
        }
    }

    function clearAll() {
        popupModel.clear();
        for (const n of list.slice()) {
            n.dismiss();
        }
        unread = 0;
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

    function dropPopup(id) {
        for (let i = popupModel.count - 1; i >= 0; i--) {
            if (popupModel.get(i).nid === id) {
                popupModel.remove(i);
            }
        }
    }

    ListModel {
        id: popupModel
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = new Date();
            root.times = t;

            if (n.lastGeneration) {
                return;
            }
            if (!root.centerOpen) {
                root.unread += 1;
            }

            const urgent = n.urgency === NotificationUrgency.Critical;
            if (root.centerOpen || (root.doNotDisturb && !urgent)) {
                return;
            }
            root.dropPopup(n.id);
            popupModel.append({
                nid: n.id
            });
            while (popupModel.count > Constants.MAX_NOTIFICATION_POPUPS) {
                popupModel.remove(0);
            }
        }
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
