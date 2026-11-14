pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick

// The login screen (greeter/shell.qml, run by greetd) signing someone in: the accounts and
// desktop sessions to choose from, and the conversation with greetd. Only the greeter uses
// this; the bar never touches it.
Singleton {
    id: root

    // ---- who and what ---------------------------------------------------------------------

    // [{ name, displayName, picture }]: the accounts that can log in
    property var users: []
    // [{ id, name, command, desktopNames }]: /usr/share/wayland-sessions
    property var sessions: []

    // the account being signed in ("" while the user tiles show)
    property string selectedUser: ""
    readonly property var user: users.find(u => u.name === selectedUser) ?? null

    // the session to start: the one chosen (at first the last one used), else Hyprland, else
    // the first
    property string sessionId: saved.lastSession
    readonly property var session: sessions.find(s => s.id === sessionId) ?? sessions.find(s => /hyprland/i.test(s.id)) ?? sessions[0] ?? null

    // ---- signing in -------------------------------------------------------------------------

    // the password box
    property string typed: ""
    property string error: ""
    // a non-error message from PAM (e.g. "Place your finger on the reader")
    property string info: ""

    // greetd is waiting for an answer to `prompt` (normally "Password:")
    property bool awaitingResponse: false
    property string prompt: ""
    property bool echoResponse: false

    // a submitted password, held until greetd asks for it
    property string pending: ""
    // an answer was sent and greetd hasn't replied yet
    property bool checking: false
    readonly property bool busy: checking || pending !== ""

    // signed in: "Welcome" shows for a moment, then the session starts
    property bool welcome: false

    function selectUser(name) {
        error = "";
        info = "";
        typed = "";
        pending = "";
        selectedUser = name;
        // greetd keeps the user of a running session: end it before starting another
        Greetd.cancelSession();
        if (name !== "") {
            startSession();
        }
    }

    function startSession() {
        awaitingResponse = false;
        checking = false;
        Greetd.createSession(selectedUser);
    }

    function submit() {
        if (busy || welcome || selectedUser === "") {
            return;
        }
        error = "";
        pending = typed;
        typed = "";
        if (awaitingResponse) {
            respond();
        } else if (Greetd.state === GreetdState.Inactive) {
            startSession();
        }
    }

    function respond() {
        const answer = pending;
        pending = "";
        awaitingResponse = false;
        checking = true;
        Greetd.respond(answer);
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.checking = false;
            if (responseRequired) {
                root.prompt = message;
                root.echoResponse = echoResponse;
                root.awaitingResponse = true;
                if (root.pending !== "") {
                    root.respond();
                }
            } else if (error) {
                root.error = message;
            } else {
                root.info = message;
            }
        }

        function onAuthFailure(message) {
            root.checking = false;
            root.pending = "";
            root.awaitingResponse = false;
            root.error = "The user name or password is incorrect.";
            // greetd ends the session after a failure: start the next attempt once it has
            Qt.callLater(root.startSession);
        }

        function onError(message) {
            root.checking = false;
            root.pending = "";
            root.error = message || "Couldn't sign in.";
        }

        function onReadyToLaunch() {
            root.checking = false;
            root.welcome = true;
            saved.lastSession = root.session?.id ?? "";
            // greetd wants the greeter gone soon after launching, so show "Welcome" first
            welcomeTimer.start();
        }
    }

    Timer {
        id: welcomeTimer
        interval: 1400
        onTriggered: root.launch()
    }

    function launch() {
        const s = session;
        if (!s) {
            welcome = false;
            error = "No desktop session was found.";
            return;
        }
        Greetd.launch(["sh", "-c", s.command], ["XDG_SESSION_TYPE=wayland", `XDG_SESSION_DESKTOP=${s.id}`, `XDG_CURRENT_DESKTOP=${s.desktopNames || s.id}`], true);
    }

    // ---- power ------------------------------------------------------------------------------

    function sleep() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function restart() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function shutDown() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    // ---- reading accounts and sessions ------------------------------------------------------

    function script(name) {
        return Qt.resolvedUrl("../greeter/" + name).toString().replace(/^file:\/\//, "");
    }

    function rows(text) {
        return text.split("\n").filter(line => line.trim() !== "").map(line => line.split("\t"));
    }

    Process {
        running: true
        command: ["sh", root.script("users.sh")]

        stdout: StdioCollector {
            onStreamFinished: {
                root.users = root.rows(text).map(([name, displayName, picture]) => ({
                            name,
                            displayName: displayName || name,
                            picture: picture ?? ""
                        }));
                // one account: straight to its password, like Win7
                if (root.users.length === 1) {
                    root.selectUser(root.users[0].name);
                }
            }
        }
    }

    Process {
        running: true
        command: ["sh", root.script("sessions.sh")]

        stdout: StdioCollector {
            onStreamFinished: {
                root.sessions = root.rows(text).map(([id, name, command, desktopNames]) => ({
                            id,
                            name,
                            command,
                            desktopNames: desktopNames ?? ""
                        }));
            }
        }
    }

    // the session used last time (in the greeter user's state directory)
    FileView {
        path: Quickshell.statePath("greeter.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            property string lastSession: ""
        }
    }
}
