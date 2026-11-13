import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../../services"

// While polkit wants a password, every screen dims (like Win7's secure desktop) and the screen
// that was focused shows the UAC dialog. For a blurred backdrop add a layer rule for "aero-auth".
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool primary: AuthAgent.screenName === modelData.name || (!Quickshell.screens.some(s => s.name === AuthAgent.screenName) && Quickshell.screens[0] === modelData)

        visible: AuthAgent.active || dim.opacity > 0.01
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "aero-auth"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: AuthAgent.active && primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            id: dim
            anchors.fill: parent
            color: "black"
            opacity: AuthAgent.active ? 0.55 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }
        }

        // it's modal: clicks outside the dialog go nowhere
        MouseArea {
            anchors.fill: parent
        }

        Loader {
            anchors.centerIn: parent
            active: window.primary && AuthAgent.active

            sourceComponent: AuthDialog {
                focus: true
                opacity: 0
                scale: 0.96
                Component.onCompleted: {
                    opacity = 1;
                    scale = 1;
                    forceActiveFocus();
                    focusPassword();
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
