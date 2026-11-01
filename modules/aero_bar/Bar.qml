import Quickshell
import Quickshell.Wayland
import QtQuick

import "components"
import "tray"
import "flyout"

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

        implicitHeight: Constants.FULL_ALLOCATED_HEIGHT
        exclusiveZone: Constants.BAR_HEIGHT
        color: "transparent"

        mask: Region {
            item: bar
            Region {
                item: flyout.aeroframe
            }
        }

        Rectangle {
            id: bar

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: Constants.BAR_HEIGHT
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

                Tray {}

                AudioInline {
                    id: audioInlineOther
                    flyoutEl: flyout
                }

                AudioInline {
                    id: audioInline
                    flyoutEl: flyout
                }

                Time {
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    date: Clock.date
                }
            }
        }

        Flyout {
            id: flyout

            anchors.bottom: bar.top
            anchors.bottomMargin: 10

            FlyoutPane {
                owner: audioInlineOther

                Row {
                    padding: 8

                    Text {
                        text: "other text aaahaahklsdhflkasdjhflkasdjhlkfahsd"
                    }
                }
            }

            FlyoutPane {
                owner: audioInline

                Row {
                    padding: 8

                    Text {
                        text: "i am text here"
                    }
                }
            }
        }
    }
}
