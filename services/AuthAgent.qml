pragma Singleton

import Quickshell
import Quickshell.Services.Polkit
import QtQuick

// only one polkit agent per session: stop hyprpolkitagent / polkit-gnome first
Singleton {
    id: root

    readonly property alias agent: agent
    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive && flow !== null
    property string screenName: ""
    readonly property string screen: Screens.resolve(screenName)
    property bool wrongPassword: false
    // switching identity also reports a failure; only one after a submit counts
    property bool submitted: false

    function submit(password) {
        if (flow?.isResponseRequired) {
            wrongPassword = false;
            submitted = true;
            flow.submit(password);
        }
    }

    function cancel() {
        flow?.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.screenName = Screens.focused;
            root.wrongPassword = false;
            root.submitted = false;
        }
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed() {
            root.wrongPassword = root.submitted;
            root.submitted = false;
        }
    }
}
