import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../../services"

// Balloons above the notification area of the focused screen, newest at the bottom.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: Notifications.popups.count > 0 && (Hyprland.focusedMonitor?.name ?? Quickshell.screens[0].name) === modelData.name

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

                    notification: Notifications.find(nid)
                    tail: index === Notifications.popups.count - 1
                    onNotificationChanged: {
                        if (!notification) {
                            Notifications.dropPopup(nid);
                        }
                    }
                    onTimedOut: {
                        if (notification?.transient) {
                            notification.expire();
                        }
                        Notifications.dropPopup(nid);
                    }

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
