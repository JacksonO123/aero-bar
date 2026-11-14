pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick

Singleton {
    id: root

    property var users: []
    property var sessions: []

    property string selectedUser: ""
    readonly property var user: users.find(u => u.name === selectedUser) ?? null

    property string sessionId: saved.lastSession
    readonly property var session: sessions.find(s => s.id === sessionId) ?? sessions.find(s => /hyprland/i.test(s.id)) ?? sessions[0] ?? null

    property string typed: ""
    property string error: ""
    property string info: ""

    property bool awaitingResponse: false
    property string prompt: ""
    property bool echoResponse: false
    readonly property bool echoing: awaitingResponse && echoResponse

    property string pending: ""
    property bool checking: false
    readonly property bool busy: checking || pending !== ""

    property bool welcome: false

    function selectUser(name) {
        error = "";
        info = "";
        typed = "";
        pending = "";
        selectedUser = name;
        // greetd keeps a running session's user: cancel it before starting another
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
            // no restart here: greetd's reply to Quickshell's cancel would read as a login;
            // submit() starts a new session
            root.error = "The user name or password is incorrect.";
        }

        function onError(message) {
            root.checking = false;
            root.pending = "";
            root.welcome = false;
            root.error = message || "Couldn't sign in.";
        }

        function onReadyToLaunch() {
            root.checking = false;
            root.welcome = true;
            saved.lastSession = root.session?.id ?? "";
            // greetd wants the greeter gone soon after launch: show "Welcome" first
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
        const environment = ["XDG_SESSION_TYPE=wayland", `XDG_SESSION_DESKTOP=${s.id}`, `XDG_CURRENT_DESKTOP=${s.desktopNames || s.id}`];
        // greetd runs the argv joined with spaces through sh -c
        Greetd.launch([s.command], environment, true);
    }

    function sleep() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function restart() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function shutDown() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

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

    FileView {
        path: Quickshell.statePath("greeter.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            property string lastSession: ""
        }
    }
}
