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

    power: GreeterState

    onBackgroundClicked: {
        sessionMenu.visible = false;
        signIn.focusInput();
    }

    // ---- the session to start -----------------------------------------------------------------

    controls: Item {
        visible: !GreeterState.welcome && GreeterState.session !== null
        width: sessionRow.width
        height: 38

        Row {
            id: sessionRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            opacity: sessionMouse.containsMouse ? 1 : 0.85

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

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

    SignInBox {
        id: signIn
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.signingIn
        picture: GreeterState.user?.picture ?? ""
        name: GreeterState.user?.displayName ?? GreeterState.selectedUser
        message: GreeterState.error || GreeterState.info
        busy: GreeterState.busy
        // PAM can ask for something other than a password (a code, a user name)
        placeholder: GreeterState.echoing ? GreeterState.prompt.replace(/:\s*$/, "") : "Password"
        echoMode: GreeterState.echoing ? TextInput.Normal : TextInput.Password
        text: GreeterState.typed
        onTextChanged: GreeterState.typed = text
        onSubmitted: GreeterState.submit()
    }

    LogonButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.signingIn && GreeterState.users.length > 1 && !GreeterState.busy
        text: "Switch User"
        onClicked: GreeterState.selectUser("")
    }
}
