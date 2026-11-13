import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../../services"

// The Alt+Tab panel / Flip 3D stack on the focused screen. It takes the keyboard while open:
// letting go of Alt (Super for Flip 3D) or Enter switches, Esc cancels, arrows / Tab step.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: Switcher.active && (Switcher.screenName === modelData.name || (!Quickshell.screens.some(s => s.name === Switcher.screenName) && Quickshell.screens[0] === modelData))

        visible: wanted
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {
            item: Switcher.mode === "flip" ? flipLoader : altTabLoader
        }

        WlrLayershell.namespace: "aero-switcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onWantedChanged: {
            if (wanted) {
                keys.forceActiveFocus();
            }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                    Switcher.step(1);
                } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                    Switcher.step(-1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    Switcher.commit();
                } else if (event.key === Qt.Key_Escape) {
                    Switcher.close();
                } else {
                    return;
                }
                event.accepted = true;
            }

            Keys.onReleased: event => {
                const alt = event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr;
                const sup = event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta;
                if ((Switcher.mode === "alttab" && alt) || (Switcher.mode === "flip" && sup)) {
                    Switcher.commit();
                }
            }
        }

        Loader {
            id: altTabLoader
            anchors.centerIn: parent
            active: window.wanted && Switcher.mode === "alttab"
            sourceComponent: AltTabView {
                maxWidth: window.width - 120
            }
        }

        Loader {
            id: flipLoader
            anchors.fill: parent
            active: window.wanted && Switcher.mode === "flip"
            sourceComponent: FlipView {}
        }
    }
}
