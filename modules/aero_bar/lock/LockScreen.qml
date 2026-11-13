import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services"

// The session lock (ext-session-lock): one logon surface per screen while LockState.locked.
WlSessionLock {
    locked: LockState.locked

    // (not a Binding child: children here become the per-screen surface)
    Component.onCompleted: LockState.secure = Qt.binding(() => secure)

    WlSessionLockSurface {
        color: "black"

        LockSurface {}
    }
}
