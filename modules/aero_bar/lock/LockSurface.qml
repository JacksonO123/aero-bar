import QtQuick
import "../components"
import "../../../services"

// What every screen shows while locked: the Win7 logon screen with the user tile, a password
// box and its round arrow button, the time, and a power button.
LogonScreen {
    powerActions: [
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

    onBackgroundClicked: password.focusInput()

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

    PasswordBox {
        id: password
        anchors.horizontalCenter: parent.horizontalCenter
        busy: LockState.busy
        text: LockState.typed
        onTextChanged: LockState.typed = text
        onSubmitted: LockState.submit()
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: LockState.error !== ""
        text: LockState.error
        font.pixelSize: 14
    }
}
