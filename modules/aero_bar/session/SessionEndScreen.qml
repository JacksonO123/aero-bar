import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../../services"

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData
        visible: SessionEnd.active || view.opacity > 0.01
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "aero-session-end"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: SessionEnd.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        SessionEndView {
            id: view
        }
    }
}
