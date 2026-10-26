import Quickshell
import Quickshell.Wayland
import QtQuick
import "components"
import "../../services"
import "../../utils/path.js" as PathUtils
import "../../utils/constants.js" as Constants

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

        implicitHeight: Constants.BAR_HEIGHT
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TwoToneBackground {}

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 18
                width: leftIcons.implicitWidth
                color: "transparent"

                Row {
                    id: leftIcons
                    height: parent.height
                    spacing: 12

                    ArchIcon {
                        onClicked: Quickshell.execDetached([PathUtils.pathRelativeToHome(".local/bin/control-center")])
                    }

                    AppIcons {
                        apps: Apps.apps
                    }
                }
            }

            WorkspaceButtons {
                anchors.centerIn: parent
            }

            Row {
                id: rightIcons
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 4
                spacing: 4

                OpenAppList {}

                TimeBox {
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    date: Clock.date
                }
            }
        }
    }
}
