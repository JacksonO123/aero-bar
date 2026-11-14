pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick
import "../utils/constants.js" as Constants

// lock with: qs ipc call lock lock, or loginctl lock-session (hypridle too)
Singleton {
    id: root

    property bool locked: false
    property bool secure: false

    property string typed: ""
    property string error: ""
    property string pending: ""
    // respond() leaves pam.responseRequired set until PAM's next message
    property bool checking: false
    property string pamNote: ""
    readonly property bool busy: (pam.active && !pam.responseRequired) || checking || pending !== ""

    function lock() {
        if (!locked) {
            typed = "";
            error = "";
            locked = true;
        }
    }

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

    function lockLost() {
        console.warn("LockState: the compositor refused or ended the session lock");
        locked = false;
        // still suspend: another locker may hold the lock
        runAfterLock();
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
            // no completed() follows a failed start()
            pending = "";
            error = "Couldn't start the password check.";
        }
    }

    function respond() {
        const answer = pending;
        pending = "";
        checking = true;
        pam.respond(answer);
    }

    PamContext {
        id: pam

        config: Constants.LOCK_PAM_CONFIG

        onPamMessage: {
            root.checking = false;
            if (responseRequired && root.pending !== "") {
                root.respond();
            } else if (!responseRequired) {
                // e.g. pam_faillock's lockout: more useful than "incorrect"
                root.pamNote = root.pamNote ? `${root.pamNote} ${message}` : message;
                if (messageIsError) {
                    root.error = message;
                }
            }
        }

        onCompleted: result => {
            root.pending = "";
            root.checking = false;
            if (result === PamResult.Success) {
                root.error = "";
                root.locked = false;
            } else if (result === PamResult.MaxTries) {
                root.error = "Too many attempts. Wait a moment and try again.";
            } else if (result === PamResult.Failed) {
                root.error = root.pamNote || "The password is incorrect. Try again.";
            } else {
                root.error = root.pamNote || "Couldn't check the password.";
            }
            root.pamNote = "";
        }
    }

    // logind's object path for this session, escaped like sd-bus does
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

    readonly property string lockSignalRule: {
        const rule = "type='signal',interface='org.freedesktop.login1.Session',member='Lock'";
        return sessionPath !== "" ? `${rule},path='${sessionPath}'` : rule;
    }

    property double logindStartedAt: 0
    property int retryDelay: 5000

    Process {
        id: logind

        running: true
        command: ["dbus-monitor", "--system", root.lockSignalRule]

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("member=Lock")) {
                    root.lock();
                }
            }
        }

        onStarted: root.logindStartedAt = Date.now()

        onExited: {
            if (Date.now() - root.logindStartedAt > 60000) {
                root.retryDelay = 5000;
                logindRetry.interval = 250;
            } else {
                logindRetry.interval = root.retryDelay;
                root.retryDelay = Math.min(60000, root.retryDelay * 2);
            }
            logindRetry.start();
        }
    }

    Timer {
        id: logindRetry
        onTriggered: logind.running = true
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }
}
