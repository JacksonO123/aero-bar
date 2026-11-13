import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../components"
import "../../../services"

// "Window Color and Appearance": pick the glass colour for the whole shell. Changes preview
// live; Save keeps them, Cancel / Esc / close puts the old colour back.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: Theme.dialogOpen && (Theme.dialogScreen === modelData.name || (Theme.dialogScreen === "" && (Hyprland.focusedMonitor?.name ?? Quickshell.screens[0].name) === modelData.name))
        readonly property real shadowMargin: 24

        visible: wanted || dialog.opacity > 0.01
        exclusiveZone: 0
        implicitWidth: dialog.width + shadowMargin * 2
        implicitHeight: dialog.height + shadowMargin * 2
        color: "transparent"

        WlrLayershell.namespace: "aero-dialog"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onWantedChanged: {
            if (wanted) {
                dialog.forceActiveFocus();
            }
        }

        AeroWindow {
            id: dialog

            x: window.shadowMargin
            y: window.shadowMargin + (window.wanted ? 0 : 10)
            width: 540
            height: body.height + 40
            opacity: window.wanted ? 1 : 0
            title: "Window Color and Appearance"
            focus: true
            onCloseClicked: Theme.cancel()

            Keys.onEscapePressed: Theme.cancel()
            Keys.onReturnPressed: Theme.save()
            Keys.onEnterPressed: Theme.save()

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: body
                width: dialog.width - 18
                height: footer.y + footer.height

                Text {
                    id: heading
                    x: 20
                    y: 16
                    text: "Change the color of your window borders, Start menu, and taskbar"
                    color: "#1e3c78"
                    font.pixelSize: 15
                }

                Grid {
                    id: swatches
                    x: 16
                    y: heading.y + heading.height + 14
                    columns: 9
                    spacing: 2

                    Repeater {
                        model: Theme.swatches

                        ColorSwatch {
                            required property var modelData
                            color: modelData.color
                            selected: Theme.colorName === modelData.name
                            onClicked: Theme.pick(modelData.name)
                        }
                    }
                }

                Text {
                    id: current
                    x: 20
                    y: swatches.y + swatches.height + 10
                    text: "Current color: " + Theme.colorName
                    color: "#333"
                    font.pixelSize: 12
                }

                CheckBox {
                    id: transparency
                    x: 20
                    y: current.y + current.height + 14
                    text: "Enable transparency"
                    checked: Theme.transparency
                    onToggled: checked => Theme.previewTransparency = checked
                }

                Row {
                    id: intensityRow
                    x: 20
                    y: transparency.y + transparency.height + 12
                    spacing: 12

                    Text {
                        width: 92
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Color intensity:"
                        color: "#1a1a1a"
                        font.pixelSize: 12
                    }

                    AeroSlider {
                        width: 300
                        knobSize: 26
                        trackHeight: 6
                        value: Theme.intensity
                        onMoved: value => Theme.previewIntensity = Math.max(0.1, value)
                    }
                }

                // color mixer, folded away like Win7's
                Item {
                    id: mixerToggle
                    x: 20
                    y: intensityRow.y + intensityRow.height + 8
                    width: toggleRow.width
                    height: 22

                    property bool open: false

                    Row {
                        id: toggleRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            border.width: 1
                            border.color: toggleMouse.containsMouse ? "#3c7fb1" : "#9a9a9a"
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: "#ffffff"
                                }
                                GradientStop {
                                    position: 1
                                    color: toggleMouse.containsMouse ? "#cfe6f8" : "#d8d8d8"
                                }
                            }

                            MediaGlyph {
                                anchors.centerIn: parent
                                width: 6
                                height: 8
                                kind: "play"
                                color: "#4a4a4a"
                                shadow: false
                                rotation: mixerToggle.open ? -90 : 90

                                Behavior on rotation {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: mixerToggle.open ? "Hide color mixer" : "Show color mixer"
                            color: toggleMouse.containsMouse ? "#3399ff" : "#1e3c78"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mixerToggle.open = !mixerToggle.open
                    }
                }

                Column {
                    id: mixer
                    x: 20
                    y: mixerToggle.y + mixerToggle.height + 6
                    spacing: 2
                    visible: mixerToggle.open
                    height: visible ? implicitHeight : 0

                    Repeater {
                        model: [
                            {
                                label: "Hue:",
                                key: "hsvHue"
                            },
                            {
                                label: "Saturation:",
                                key: "hsvSaturation"
                            },
                            {
                                label: "Brightness:",
                                key: "hsvValue"
                            }
                        ]

                        Row {
                            required property var modelData
                            spacing: 12

                            Text {
                                width: 92
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: "#1a1a1a"
                                font.pixelSize: 12
                            }

                            AeroSlider {
                                width: 300
                                knobSize: 26
                                trackHeight: 6
                                value: Math.max(0, Theme.tint[modelData.key])
                                onMoved: value => {
                                    const t = Theme.tint;
                                    const hsv = {
                                        hsvHue: Math.max(0, t.hsvHue),
                                        hsvSaturation: t.hsvSaturation,
                                        hsvValue: t.hsvValue
                                    };
                                    hsv[modelData.key] = Math.min(0.999, value);
                                    Theme.setCustom(Qt.hsva(hsv.hsvHue, hsv.hsvSaturation, hsv.hsvValue, 1));
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: footer
                    y: mixer.y + mixer.height + 16
                    width: parent.width
                    height: 46
                    color: "#f0f0f0"

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#dfdfdf"
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        PushButton {
                            text: "Save changes"
                            isDefault: true
                            onClicked: Theme.save()
                        }
                        PushButton {
                            text: "Cancel"
                            onClicked: Theme.cancel()
                        }
                    }
                }
            }
        }
    }
}
