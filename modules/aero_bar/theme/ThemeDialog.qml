import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"
import "../../../services"

// "Window Color and Appearance": pick the glass colour for the whole shell. Changes preview
// live; Save keeps them, Cancel / Esc / close puts the old colour back.
Variants {
    model: Quickshell.screens

    // a labelled slider: the intensity and the colour mixer's three
    component SliderRow: Row {
        id: sliderRow

        property alias label: labelText.text
        property real value

        signal moved(real value)

        spacing: 12

        Text {
            id: labelText
            width: 92
            anchors.verticalCenter: parent.verticalCenter
            color: "#1a1a1a"
            font.pixelSize: 12
        }

        AeroSlider {
            width: 300
            knobSize: 26
            trackHeight: 6
            value: sliderRow.value
            onMoved: value => sliderRow.moved(value)
        }
    }

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: Theme.dialogOpen && Theme.screen === modelData.name
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
            opacity: window.wanted ? 1 : 0
            title: "Window Color and Appearance"
            focus: true
            onCloseClicked: Theme.cancel()

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
                width: parent.width
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

                SliderRow {
                    id: intensityRow
                    x: 20
                    y: transparency.y + transparency.height + 12
                    label: "Color intensity:"
                    value: Theme.intensity
                    onMoved: value => Theme.previewIntensity = Math.max(0.1, value)
                }

                // color mixer, folded away like Win7's
                DisclosureToggle {
                    id: mixerToggle
                    x: 20
                    y: intensityRow.y + intensityRow.height + 8
                    openText: "Hide color mixer"
                    closedText: "Show color mixer"
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

                        SliderRow {
                            required property var modelData
                            label: modelData.label
                            value: Theme.mix[modelData.key]
                            onMoved: value => Theme.setMix(modelData.key, value)
                        }
                    }
                }

                DialogFooter {
                    id: footer
                    y: mixer.y + mixer.height + 16
                    width: parent.width

                    // Win7's Personalization links: on to the wallpaper (keeping the colour)
                    leading: LinkText {
                        text: "Desktop Background"
                        onClicked: {
                            const screen = Theme.screen;
                            Theme.save();
                            Wallpaper.openDialog(screen);
                        }
                    }

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
