import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../../services"
import "../session"

Scope {
    // a reload rebuilds LockState unlocked; restore it here, before the lock reloads
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

        // a refused or ended lock lets go silently; only secure changes
        function checkLost() {
            if (LockState.locked && !locked) {
                LockState.lockLost();
            }
        }

        onSecureChanged: Qt.callLater(checkLost)

        // not a Binding child: children here become the per-screen surface
        Component.onCompleted: LockState.secure = Qt.binding(() => secure)

        WlSessionLockSurface {
            color: "black"

            LockSurface {}

            // layer surfaces don't show over a session lock
            SessionEndView {}
        }
    }

    // a lock that never starts (no ext-session-lock) doesn't change secure
    Connections {
        target: LockState

        function onLockedChanged() {
            Qt.callLater(lock.checkLost);
        }
    }
}
