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
                        active: StartMenuState.open && StartMenuState.screenName === here.modelData.name
                        onClicked: StartMenuState.toggle(here.modelData.name)
                    }

                    AppIcons {
                        apps: Apps.apps
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

            FlyoutPane {
                id: mediaFlyoutPane
                owner: mediaInline

                MediaPane {
                    shown: mediaFlyoutPane.active
                }
            }

            FlyoutPane {
                id: calendarFlyoutPane
                owner: clockButton

                CalendarPane {
                    shown: calendarFlyoutPane.active
                }
            }

            FlyoutPane {
                id: volumeFlyoutPane
                owner: volumeInline

                VolumePane {
                    shown: volumeFlyoutPane.active
                    flyoutEl: flyout
                }
            }
        }

        // a click anywhere outside the bar closes a pinned (click-opened) flyout like the calendar
        HyprlandFocusGrab {
            windows: [here]
            active: flyout.pinned
            onCleared: flyout.close()
        }

        Connections {
            target: StartMenuState

            function onOpenChanged() {
                if (StartMenuState.open) {
                    flyout.close();
                }
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
    }
}
