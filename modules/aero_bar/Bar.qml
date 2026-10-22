import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import QtQuick
import Qt5Compat.GraphicalEffects
import "components"
import "../../services"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: here
        required property var modelData
        screen: modelData
        WlrLayershell.namespace: "aero-bar"

        anchors {
            bottom: true
            left: true
            right: true
        }
        implicitHeight: 41
        color: "transparent"

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TwoToneBackground {}

            RowLayout {
                id: rootRowLayout
                anchors.fill: parent
                spacing: 2

                ArchIcon {
                    onClicked: Quickshell.execDetached(["/home/jotto/.local/bin/control-center"])
                    Layout.rightMargin: 12
                    Layout.leftMargin: 16
                }

                AppIcons {
                    apps: Apps.apps
                }

                Item {
                    Layout.fillWidth: true
                }

                WorkspaceButtons {}

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd HH:mm")
                    color: "#cdd6f4"
                }
            }
        }
    }
}
