import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../../services"

// The session lock (ext-session-lock): one logon surface per screen while LockState.locked.
Scope {
    // A config reload rebuilds LockState unlocked, and the new lock below takes over the old
    // one: unless it is told to stay locked by then, it lets go. So the lock state is carried
    // across reloads here, ahead of the lock (children reload in order).
    PersistentProperties {
        id: persist

        reloadableId: "aeroLock"

        property bool locked: false

        onLoaded: {
            if (locked) {
                LockState.locked = true;
            }
            locked = Qt.binding(() => LockState.locked);
        }
    }

    WlSessionLock {
        id: lock

        locked: persist.locked

        // the compositor can refuse the lock (another locker holds it) or end it. The lock lets
        // go then without saying so; only `secure` changes. (After the change is through.)
        function checkLost() {
            if (LockState.locked && !locked) {
                LockState.lockLost();
            }
        }

        onSecureChanged: Qt.callLater(checkLost)

        // (not a Binding child: children here become the per-screen surface)
        Component.onCompleted: LockState.secure = Qt.binding(() => secure)

        WlSessionLockSurface {
            color: "black"

            LockSurface {}
        }
    }

    // a lock that couldn't even start (e.g. no ext-session-lock support) changes nothing
    Connections {
        target: LockState

        function onLockedChanged() {
            Qt.callLater(lock.checkLost);
        }
    }
}
