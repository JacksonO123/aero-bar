import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../../services"

// blur needs a Hyprland layer rule for namespace "aero-start-menu"
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: StartMenuState.open && StartMenuState.screen === modelData.name

        visible: wanted || menu.opacity > 0.01

        anchors {
            bottom: true
            left: true
        }
        margins {
            left: 4
        }

        // 0: reserve nothing, but stay clear of the bar's exclusive zone
        exclusiveZone: 0
        implicitWidth: menu.implicitWidth
        implicitHeight: menu.implicitHeight
        color: "transparent"

        WlrLayershell.namespace: "aero-start-menu"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        mask: Region {
            item: menu.maskFrame
            Region {
                item: menu.maskTile
            }
        }

        // only once mapped: a grab on an unmapped window is cleared at once
        HyprlandFocusGrab {
            windows: [window]
            active: window.wanted && window.visible
            onCleared: StartMenuState.close()
        }

        StartMenuContent {
            id: menu
            anchors.fill: parent
            shown: window.wanted
            focus: true
        }
    }
}
