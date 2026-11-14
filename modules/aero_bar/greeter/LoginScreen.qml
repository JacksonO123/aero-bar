import Quickshell
import Quickshell.Wayland
import QtQuick
import "../lock"
import "../../../services"

Variants {
    id: root

    property string primary: ""

    model: Quickshell.screens

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
