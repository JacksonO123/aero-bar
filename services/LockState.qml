pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick
import "../utils/constants.js" as Constants

// Locks the session with the Win7-style logon screen (modules/aero_bar/lock) and checks the
// password with PAM.
//
// Locks on any of:
//   qs ipc call lock lock
//   loginctl lock-session          (so hypridle's lock_cmd / before_sleep_cmd work too)
//   Start menu > Lock, and before Sleep
Singleton {
    id: root

    property bool locked: false
    // the compositor has confirmed every screen is covered (set by the lock surfaces)
    property bool secure: false
    // the password box, shared by the lock surfaces on every screen
    property string typed: ""
    property string error: ""
    readonly property bool busy: pam.active && !pam.responseRequired || pending !== ""
    property string pending: ""

    function lock() {
        if (!locked) {
            typed = "";
            error = "";
            locked = true;
        }
    }

    // lock, and run `action` only once the lock is really up (e.g. suspend). If the compositor
    // never confirms, it still runs after a few seconds rather than not at all.
    property var afterLock: null

    function lockThen(action) {
        lock();
        if (secure) {
            action();
            return;
        }
        afterLock = action;
        afterLockTimeout.restart();
    }

    function runAfterLock() {
        const action = afterLock;
        afterLock = null;
        afterLockTimeout.stop();
        if (action) {
            action();
        }
    }

    onSecureChanged: {
        if (secure) {
            runAfterLock();
        }
    }

    Timer {
        id: afterLockTimeout
        interval: 3000
        onTriggered: root.runAfterLock()
    }

    function submit() {
        if (typed === "" || busy) {
            return;
        }
        error = "";
        pending = typed;
        typed = "";
        if (pam.responseRequired) {
            respond();
        } else if (!pam.active && !pam.start()) {
            // no completed() will follow, so don't wait for one
            pending = "";
            error = "Couldn't start the password check.";
        }
    }

    function respond() {
        const answer = pending;
        pending = "";
        pam.respond(answer);
    }

    PamContext {
        id: pam

        config: Constants.LOCK_PAM_CONFIG

        onPamMessage: {
            if (responseRequired && root.pending !== "") {
                root.respond();
            } else if (messageIsError) {
                root.error = message;
            }
        }

        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success) {
                root.error = "";
                root.locked = false;
            } else if (result === PamResult.MaxTries) {
                root.error = "Too many attempts. Wait a moment and try again.";
            } else if (result === PamResult.Failed) {
                root.error = "The password is incorrect. Try again.";
            } else {
                root.error = "Couldn't check the password.";
            }
        }
    }

    // logind's Lock signal for this session (`loginctl lock-session`, hypridle, ...)
    readonly property string sessionPath: {
        const id = Quickshell.env("XDG_SESSION_ID") ?? "";
        let out = "";
        for (let i = 0; i < id.length; i++) {
            const c = id[i];
            const plain = /[A-Za-z0-9]/.test(c) && !(i === 0 && /[0-9]/.test(c));
            out += plain ? c : "_" + c.charCodeAt(0).toString(16).padStart(2, "0");
        }
        return out !== "" ? "/org/freedesktop/login1/session/" + out : "";
    }

    property double logindStartedAt: 0

    Process {
        id: logind
        running: true
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Session',member='Lock'" + (root.sessionPath !== "" ? ",path='" + root.sessionPath + "'" : "")]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("member=Lock")) {
                    root.lock();
                }
            }
        }
        onStarted: root.logindStartedAt = Date.now()
        onExited: {
            // it ran fine for a while: this is a one-off exit, not a failure loop
            if (Date.now() - root.logindStartedAt > 60000) {
                restart.interval = 5000;
            }
            restart.start();
        }
    }

    // if dbus-monitor keeps failing, retry less and less often (5 s, 10 s, ... up to a minute)
    Timer {
        id: restart
        interval: 5000
        onTriggered: {
            logind.running = true;
            interval = Math.min(60000, interval * 2);
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }
}
