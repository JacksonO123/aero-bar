pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import QtQuick

// The polkit agent: when a program asks for admin rights (pkexec, GParted, mounting a disk...)
// polkit asks us for a password, and modules/aero_bar/polkit shows a Win7 UAC-style prompt.
//
// Only one agent can be registered per session: stop hyprpolkitagent / polkit-gnome first.
Singleton {
    id: root

    readonly property alias agent: agent
    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive && flow !== null
    readonly property bool registered: agent.isRegistered
    // the prompt shows on the screen that was focused when the request came in
    property string screenName: ""
    // the last attempt failed; cleared when the user types again
    property bool wrongPassword: false

    function submit(password) {
        if (flow?.isResponseRequired) {
            wrongPassword = false;
            flow.submit(password);
        }
    }

    function cancel() {
        flow?.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.screenName = Hyprland.focusedMonitor?.name ?? "";
            root.wrongPassword = false;
        }
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed() {
            root.wrongPassword = true;
        }
    }
}
