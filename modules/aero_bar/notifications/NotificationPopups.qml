import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../../services"

// Balloons above the notification area of the focused screen, newest at the bottom.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: Notifications.popups.count > 0 && Screens.focused === modelData.name

        visible: wanted
        anchors.bottom: true
        anchors.right: true
        margins.right: 6
        exclusiveZone: 0
        implicitWidth: 330 + 24
        implicitHeight: Math.max(1, column.height + 14)
        color: "transparent"
        mask: Region {
            item: column
        }

        WlrLayershell.namespace: "aero-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: column
            x: 12
            anchors.bottom: parent.bottom
            spacing: 8

            Repeater {
                model: Notifications.popups

                Balloon {
                    id: balloon

                    required property int nid
                    required property int index

                    // every screen has a copy; only the one showing can hold its countdown
                    readonly property bool holding: hovered && window.wanted

                    notification: Notifications.find(nid)
                    tail: index === Notifications.popups.count - 1
                    onHoldingChanged: holding ? Notifications.holdPopup(nid) : Notifications.countDown(notification)

                    opacity: 0
                    Component.onCompleted: opacity = 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 220
                        }
                    }
                }
            }
        }
    }
}
