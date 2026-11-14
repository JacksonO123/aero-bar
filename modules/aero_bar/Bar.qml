import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "components"
import "tray"
import "flyout"
import "flyout/panes"
import "overview"

import "../../services"
import "../../utils/constants.js" as Constants

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: here
        required property var modelData
        screen: modelData
        WlrLayershell.namespace: "aero-bar"
        WlrLayershell.keyboardFocus: flyout.pinned && (flyout.pane?.wantsKeyboard ?? false) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            bottom: true
            left: true
            right: true
        }

        implicitHeight: Constants.FULL_ALLOCATED_HEIGHT
        exclusiveZone: Constants.BAR_HEIGHT
        color: "transparent"

        // input only where something is drawn: the bar, an open flyout, the overview
        mask: Region {
            item: bar

            Region {
                item: flyout.aeroframe
            }

            Region {
                item: overview.maskItem
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
                        active: StartMenuState.open && StartMenuState.screen === here.modelData.name
                        onClicked: StartMenuState.toggle(here.modelData.name)
                    }

                    AppIcons {
                        apps: Apps.apps
                        flyoutEl: flyout
                    }
                }
            }

            WorkspaceButtons {
                id: workspaceButtons
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

                MediaInline {
                    id: mediaInline
                    flyoutEl: flyout
                }

                ActionCenterInline {
                    id: actionCenter
                    flyoutEl: flyout
                }

                NetworkInline {
                    id: networkButton
                    flyoutEl: flyout
                }

                BluetoothInline {
                    id: bluetoothButton
                    flyoutEl: flyout
                }

                VolumeInline {
                    id: volumeInline
                    flyoutEl: flyout
                }

                Time {
                    id: clockButton
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    date: Clock.date
                    active: flyout.pinned && flyout.current === clockButton
                    onClicked: flyout.toggle(clockButton)
                }
            }
        }

        Flyout {
            id: flyout

            anchors.bottom: bar.top
            anchors.bottomMargin: 10

            AppPane {
                flyoutEl: flyout
                // the bar window sits at the bottom of its screen
                windowOrigin: Qt.point(here.modelData.x, here.modelData.y + here.modelData.height - here.height)
            }

            MediaPane {
                owner: mediaInline
                flyoutEl: flyout
            }

            CalendarPane {
                owner: clockButton
            }

            NotificationsPane {
                owner: actionCenter
            }

            NetworkPane {
                owner: networkButton
            }

            BluetoothPane {
                owner: bluetoothButton
            }

            VolumePane {
                owner: volumeInline
                flyoutEl: flyout
            }
        }

        WorkspaceOverview {
            id: overview
            anchorItem: workspaceButtons
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bar.top
            anchors.bottomMargin: 10
        }

        // a click anywhere outside the bar closes a pinned (click-opened) flyout like the calendar
        HyprlandFocusGrab {
            windows: [here]
            active: flyout.pinned
            onCleared: flyout.close()
        }

        // the start menu opening closes any flyout
        Connections {
            target: StartMenuState

            function onOpenChanged() {
                if (StartMenuState.open) {
                    flyout.close();
                }
            }
        }
    }
}
