import QtQuick
import "../components"
import "../lock"
import "../../../services"

// The login screen: pick an account (when there is more than one), type its password, and
// "Welcome" while the desktop session starts. The session to start is chosen bottom right.
LogonScreen {
    id: root

    readonly property bool choosing: GreeterState.selectedUser === "" && !GreeterState.welcome
    readonly property bool signingIn: GreeterState.selectedUser !== "" && !GreeterState.welcome

    powerActions: [
        {
            label: "Sleep",
            command: GreeterState.sleep
        },
        {
            label: "Restart",
            command: GreeterState.restart
        },
        {
            label: "Shut down",
            command: GreeterState.shutDown
        }
    ]

    onBackgroundClicked: {
        sessionMenu.visible = false;
        password.focusInput();
    }

    // ---- the session to start -----------------------------------------------------------------

    controls: Item {
        id: sessionChooser

        property real hoverT: sessionMouse.containsMouse ? 1 : 0

        visible: !GreeterState.welcome && GreeterState.session !== null
        width: sessionRow.width
        height: 38

        Behavior on hoverT {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        Row {
            id: sessionRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            opacity: 0.85 + 0.15 * sessionChooser.hoverT

            CaptionText {
                anchors.verticalCenter: parent.verticalCenter
                text: GreeterState.session?.name ?? ""
                font.pixelSize: 16
                font.underline: sessionMouse.containsMouse
            }

            MediaGlyph {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 9
                kind: "play"
                rotation: -90
                color: "white"
            }
        }

        MouseArea {
            id: sessionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sessionMenu.visible = !sessionMenu.visible
        }

        LogonMenu {
            id: sessionMenu
            anchors.right: parent.right
            anchors.bottom: parent.top
            anchors.bottomMargin: 8
            width: 190
            actions: GreeterState.sessions.map(s => ({
                        label: s.name,
                        checked: s.id === GreeterState.session?.id,
                        command: () => GreeterState.sessionId = s.id
                    }))
        }
    }

    // ---- "Welcome" -----------------------------------------------------------------------------

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: GreeterState.welcome
        spacing: 18

        BusyCircle {
            anchors.verticalCenter: parent.verticalCenter
            size: 36
        }

        CaptionText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Welcome"
            font.pixelSize: 40
            font.weight: Font.Light
        }
    }

    // ---- choosing an account -------------------------------------------------------------------

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.choosing
        spacing: 46

        Repeater {
            model: GreeterState.users

            UserTile {
                required property var modelData
                name: modelData.displayName
                picture: modelData.picture
                onClicked: GreeterState.selectUser(modelData.name)
            }
        }
    }

    // ---- signing in ----------------------------------------------------------------------------

    ProfileTile {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.signingIn
        size: 168
        bezel: 11
        cornerRadius: 18
        bow: 3.2
        pictureRadius: 5
        picture: GreeterState.user?.picture ?? ""
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.signingIn
        text: GreeterState.user?.displayName ?? GreeterState.selectedUser
        font.pixelSize: 28
        glow: 0.8
    }

    PasswordBox {
        id: password
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.signingIn
        busy: GreeterState.busy
        // PAM can ask for something other than a password (a code, a user name)
        placeholder: GreeterState.awaitingResponse && GreeterState.echoResponse ? GreeterState.prompt.replace(/:\s*$/, "") : "Password"
        echoMode: GreeterState.awaitingResponse && GreeterState.echoResponse ? TextInput.Normal : TextInput.Password
        text: GreeterState.typed
        onTextChanged: GreeterState.typed = text
        onSubmitted: GreeterState.submit()
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.signingIn && text !== ""
        text: GreeterState.error || GreeterState.info
        font.pixelSize: 14
    }

    LogonButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.signingIn && GreeterState.users.length > 1 && !GreeterState.busy
        text: "Switch User"
        onClicked: GreeterState.selectUser("")
    }
}
