import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services"

// The session lock (ext-session-lock): one logon surface per screen while LockState.locked.
WlSessionLock {
    locked: LockState.locked

    WlSessionLockSurface {
        color: "black"

        LockSurface {}
    }
}
