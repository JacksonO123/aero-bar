import Quickshell
import Quickshell.Wayland
import QtQuick
import "../lock"
import "../../../services"

// The login screen on every monitor: the sign-in box on one (the one with the pointer when the
// greeter started), just the background on the others.
Variants {
    id: root

    // the screen the sign-in box is on
    property string primary: ""

    model: Quickshell.screens

    // (Screens.resolve falls back on the focused screen; this one falls back on the first)
    Component.onCompleted: {
        const focused = Screens.focused;
        primary = Quickshell.screens.some(s => s.name === focused) ? focused : Quickshell.screens[0]?.name ?? "";
    }

    PanelWindow {
        id: window

        required property var modelData
        readonly property bool primary: modelData.name === root.primary

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "black"

        WlrLayershell.namespace: "aero-greeter"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Loader {
            anchors.fill: parent
            sourceComponent: window.primary ? surface : background
        }

        Component {
            id: surface

            LoginSurface {}
        }

        Component {
            id: background

            LogonBackground {}
        }
    }
}
