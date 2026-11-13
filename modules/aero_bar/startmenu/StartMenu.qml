import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../../services"

// One start menu window per screen, shown on the screen it was opened from (see StartMenuState).
// For blur behind it, add a hyprland layer rule for the "aero-start-menu" namespace.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: StartMenuState.open && Screens.resolve(StartMenuState.screenName) === modelData.name

        // stay mapped until the close animation has finished
        visible: wanted || menu.opacity > 0.01

        anchors {
            bottom: true
            left: true
        }
        margins {
            left: 4
        }

        // 0 = sit above the bar's exclusive zone instead of under it
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

        // clicking anywhere else closes it
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
