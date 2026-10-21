import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "components"

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

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

            Rectangle {
                anchors.fill: parent
                color: "transparent"

                LinearGradient {
                    anchors.fill: parent
                    start: Qt.point(0, 0)
                    end: Qt.point(0, height)

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(1, 1, 1, 1)
                        }
                        GradientStop {
                            position: 0.03
                            color: Qt.rgba(0.5, 0.5, 0.5, 0.75)
                        }
                        GradientStop {
                            position: 0.5
                            color: Qt.rgba(0.2, 0.2, 0.2, 0.75)
                        }
                        GradientStop {
                            position: 0.500001
                            color: Qt.rgba(0.1, 0.1, 0.1, 0.75)
                        }
                    }
                }
            }

            RowLayout {
                id: rootRowLayout
                anchors.fill: parent
                spacing: 2

                property var apps: [
                    {
                        cmd: ["/home/jotto/.local/bin/spotlight", "--config", "/home/jotto/.config/jotto-utils/spotlight/desktop.conf"],
                        img: "./assets/magnifying-glass-icon-reflect.png",
                        offset: 10,
                        size: 22
                    },
                    {
                        cmd: ["alacritty"],
                        img: "./assets/term-icon-reflect.png",
                        offset: 10,
                        size: 23
                    },
                    {
                        cmd: ["dolphin"],
                        img: "./assets/files-icon-reflect.png",
                        offset: 10,
                        size: 23
                    },
                    {
                        cmd: ["spotify-launcher"],
                        img: "./assets/music-icon-reflect.png",
                        offset: 10,
                        size: 22
                    },
                    {
                        cmd: ["google-chrome-stable"],
                        img: "./assets/browser-icon-reflect.png",
                        offset: 10,
                        size: 26
                    },
                ]

                Repeater {
                    model: rootRowLayout.apps

                    AppIconFrame {
                        id: entry
                        required property var modelData

                        Layout.fillHeight: true
                        implicitWidth: 62
                        onClicked: Quickshell.execDetached(entry.modelData.cmd)

                        Image {
                            id: appImage
                            property int size: entry.modelData.size

                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: entry.modelData.offset

                            source: Qt.resolvedUrl(entry.modelData.img)
                            sourceSize: Qt.size(width * 2, height * 2)
                            width: size
                            height: size * 2
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: entry.radius
                            color: "transparent"
                            opacity: entry.t

                            RadialGradient {
                                anchors.fill: parent
                                horizontalOffset: -entry.width * 0.25
                                verticalOffset: -entry.height / 2
                                horizontalRadius: entry.width * 0.75 * Math.SQRT2
                                verticalRadius: entry.height * Math.SQRT2

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: Qt.rgba(1, 1, 1, 0.38 + (0.1 * entry.p))
                                    }
                                    GradientStop {
                                        position: 0.6
                                        color: Qt.rgba(1, 1, 1, 0.04 + (0.1 * entry.p))
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Qt.rgba(1, 1, 1, 0.12 + (0.1 * entry.p))
                                    }
                                }
                            }
                        }
                    }
                }

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
