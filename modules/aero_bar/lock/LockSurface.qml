import QtQuick
import "../components"
import "../../../services"

// What every screen shows while locked: the Win7 logon screen with the user tile, a password
// box and its round arrow button, the time, and a power button.
Item {
    id: root

    anchors.fill: parent
    opacity: 0
    Component.onCompleted: {
        opacity = 1;
        field.focusInput();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 350
        }
    }

    LogonBackground {
        anchors.fill: parent
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            powerMenu.visible = false;
            field.focusInput();
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -40
        spacing: 14

        ProfileTile {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 168
            bezel: 11
            cornerRadius: 18
            bow: 3.2
            pictureRadius: 5
            picture: StartMenuState.picture
        }

        CaptionText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: StartMenuState.displayName
            font.pixelSize: 28
            glow: 0.8
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 34

            Row {
                anchors.centerIn: parent
                spacing: 8
                visible: !LockState.busy

                TextField {
                    id: field
                    width: 236
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter
                    fontSize: 14
                    placeholder: "Password"
                    echoMode: TextInput.Password
                    text: LockState.typed
                    onTextChanged: LockState.typed = text
                    onAccepted: LockState.submit()
                    Keys.onEscapePressed: LockState.typed = ""
                }

                GlassOrb {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30
                    hoverT: arrowMouse.containsMouse ? 1 : 0
                    pressedT: arrowMouse.pressed ? 1 : 0

                    MediaGlyph {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: 1
                        width: 9
                        height: 12
                        kind: "play"
                    }

                    MouseArea {
                        id: arrowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: LockState.submit()
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10
                visible: LockState.busy

                BusyCircle {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 24
                }
                CaptionText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Checking…"
                    font.pixelSize: 16
                }
            }
        }

        CaptionText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: LockState.error !== ""
            text: LockState.error
            font.pixelSize: 14
            onVisibleChanged: field.focusInput()
        }
    }

    // time and date, bottom left
    Column {
        x: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 2

        CaptionText {
            text: Qt.formatTime(Clock.date, "h:mm AP")
            font.pixelSize: 60
            font.weight: Font.Light
        }
        CaptionText {
            text: Qt.formatDate(Clock.date, "dddd, MMMM d")
            font.pixelSize: 18
        }
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44
        text: "Arch Linux"
        font.pixelSize: 22
        font.weight: Font.Light
        color: Qt.rgba(1, 1, 1, 0.85)
    }

    // power, bottom right
    GlassOrb {
        id: power
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 46
        size: 38
        lightColor: "#ffc2a8"
        baseColor: "#d8401c"
        darkColor: "#5a0c00"
        glowColor: Qt.rgba(1, 0.8, 0.7, 0.9)
        hoverT: powerMouse.containsMouse ? 1 : 0
        pressedT: powerMouse.pressed ? 1 : 0

        PowerGlyph {
            anchors.centerIn: parent
            width: 18
            height: 18
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: powerMenu.visible = !powerMenu.visible
        }
    }

    Rectangle {
        id: powerMenu
        visible: false
        anchors.right: power.right
        anchors.bottom: power.top
        anchors.bottomMargin: 8
        width: 150
        height: menuColumn.height + 6
        radius: 3
        border.width: 1
        border.color: "#979797"
        color: "#f0f0f0"

        Column {
            id: menuColumn
            x: 3
            y: 3
            width: parent.width - 6

            Repeater {
                model: [
                    {
                        label: "Sleep",
                        command: StartMenuState.sleep
                    },
                    {
                        label: "Restart",
                        command: StartMenuState.restart
                    },
                    {
                        label: "Shut down",
                        command: StartMenuState.shutDown
                    }
                ]

                Item {
                    required property var modelData
                    width: menuColumn.width
                    height: 24

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        visible: itemMouse.containsMouse
                        border.width: 1
                        border.color: "#a8d8eb"
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#f1f8fd"
                            }
                            GradientStop {
                                position: 1
                                color: "#d5ecf9"
                            }
                        }
                    }

                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData.label
                        color: "#1a1a1a"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            powerMenu.visible = false;
                            parent.modelData.command();
                        }
                    }
                }
            }
        }
    }
}
