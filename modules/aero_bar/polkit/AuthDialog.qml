import QtQuick
import Quickshell
import "../components"
import "../../../services"

// The Windows 7 UAC dialog, asking for a password on polkit's behalf.
AeroWindow {
    id: root

    readonly property var flow: AuthAgent.flow
    readonly property var identities: flow?.identities ?? []
    readonly property bool busy: flow !== null && !flow.isResponseRequired && !flow.isCompleted
    readonly property string me: Quickshell.env("USER") ?? ""

    function sameIdentity(a, b) {
        return a && b && a.id === b.id && a.isGroup === b.isGroup;
    }

    // the password box of the selected identity's tile
    property Item passwordField: null

    function focusPassword() {
        passwordField?.focusInput();
    }

    function submit() {
        if (passwordField && !busy) {
            AuthAgent.submit(passwordField.text);
            passwordField.text = "";
        }
    }

    width: 500
    title: "User Account Control"
    onCloseClicked: AuthAgent.cancel()

    Connections {
        target: AuthAgent

        function onWrongPasswordChanged() {
            if (AuthAgent.wrongPassword) {
                root.focusPassword();
            }
        }
    }

    Item {
        id: body
        width: parent.width
        height: footer.y + footer.height

        Rectangle {
            id: band
            width: parent.width
            height: 80
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1
                    color: "#e3ecf7"
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#c5d5e8"
            }

            ShieldGlyph {
                x: 18
                y: 12
                width: 46
                height: 54
            }

            Text {
                x: 82
                width: parent.width - 100
                anchors.verticalCenter: parent.verticalCenter
                text: "Do you want to allow the following program to make changes to this computer?"
                wrapMode: Text.WordWrap
                color: "#1e3c78"
                font.pixelSize: 16
            }
        }

        // what is asking
        ImageIcon {
            id: actionIcon
            x: 26
            y: band.height + 16
            size: 36
            desktopIcon: root.flow?.iconName || "dialog-password"
        }

        Column {
            id: info
            x: 82
            y: band.height + 14
            width: parent.width - x - 20
            spacing: 6

            Text {
                width: parent.width
                text: root.flow?.message ?? ""
                wrapMode: Text.Wrap
                color: "#1a1a1a"
                font.pixelSize: 12
                font.bold: true
            }

            Grid {
                visible: detailsToggle.open
                columns: 2
                columnSpacing: 14
                rowSpacing: 4

                Text {
                    text: "Action:"
                    color: "#555"
                    font.pixelSize: 12
                }
                Text {
                    text: root.flow?.actionId ?? ""
                    color: "#1a1a1a"
                    font.pixelSize: 12
                }
                Text {
                    text: "Requested by:"
                    color: "#555"
                    font.pixelSize: 12
                }
                Text {
                    text: "polkit"
                    color: "#1a1a1a"
                    font.pixelSize: 12
                }
            }
        }

        Rectangle {
            id: rule
            x: 18
            y: Math.max(actionIcon.y + actionIcon.height, info.y + info.height) + 14
            width: parent.width - 36
            height: 1
            color: "#e2e2e2"
        }

        Text {
            id: instruction
            x: 26
            y: rule.y + 12
            text: "To continue, type an administrator password, and then click Yes."
            font.pixelSize: 12
            color: "#222"
        }

        Column {
            id: tiles
            x: 22
            y: instruction.y + instruction.height + 10
            spacing: 6

            Repeater {
                model: root.identities

                Rectangle {
                    id: tile

                    required property var modelData
                    readonly property bool selected: root.sameIdentity(root.flow?.selectedIdentity, modelData) || root.identities.length === 1

                    width: 320
                    height: selected ? 76 : 56
                    radius: 4
                    color: selected ? "#eaf3fc" : tileMouse.containsMouse ? "#f2f8fd" : "transparent"
                    border.width: selected || tileMouse.containsMouse ? 1 : 0
                    border.color: selected ? "#a9c8ea" : "#cfe2f5"

                    function claimPassword() {
                        if (selected) {
                            root.passwordField = field;
                        }
                    }

                    onSelectedChanged: claimPassword()
                    Component.onCompleted: claimPassword()

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !tile.selected
                        onClicked: root.flow.selectedIdentity = tile.modelData
                    }

                    ProfileTile {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        size: tile.selected ? 60 : 42
                        bezel: tile.selected ? 5 : 4
                        cornerRadius: 7
                        bow: 1.2
                        picture: tile.modelData.string === root.me ? StartMenuState.picture : ""
                    }

                    Text {
                        x: tile.selected ? 80 : 62
                        y: tile.selected ? 12 : (parent.height - height) / 2
                        text: tile.modelData.isGroup ? "Members of " + tile.modelData.displayName : (tile.modelData.displayName || tile.modelData.string)
                        font.pixelSize: 13
                        font.bold: true
                        color: "#1a1a1a"
                    }

                    TextField {
                        id: field
                        // shows (and takes the keyboard) on the selected identity's tile
                        autoFocus: true
                        x: 80
                        y: 38
                        width: 210
                        visible: tile.selected
                        enabled: !root.busy
                        placeholder: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        onAccepted: root.submit()
                        onTextChanged: {
                            if (text !== "") {
                                AuthAgent.wrongPassword = false;
                            }
                        }
                    }
                }
            }
        }

        Text {
            id: message
            x: 26
            y: tiles.y + tiles.height + (visible ? 8 : 0)
            width: parent.width - 52
            visible: text !== ""
            height: visible ? implicitHeight : 0
            text: AuthAgent.wrongPassword ? "The password is incorrect. Try again." : root.busy ? "Checking…" : root.flow?.supplementaryMessage ?? ""
            wrapMode: Text.Wrap
            color: AuthAgent.wrongPassword || root.flow?.supplementaryIsError ? "#b3261e" : "#555"
            font.pixelSize: 12
        }

        DialogFooter {
            id: footer
            y: message.y + message.height + 16
            width: parent.width

            leading: DisclosureToggle {
                id: detailsToggle
                openText: "Hide details"
                closedText: "Show details"
            }

            PushButton {
                text: "Yes"
                isDefault: true
                enabled: !root.busy
                onClicked: root.submit()
            }
            PushButton {
                text: "No"
                onClicked: AuthAgent.cancel()
            }
        }
    }
}
