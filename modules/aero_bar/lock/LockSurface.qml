import QtQuick
import "../../../services"

// What every screen shows while locked: the Win7 logon screen with the user tile, a password
// box and its round arrow button, the time, and a power button.
LogonScreen {
    power: StartMenuState
    onBackgroundClicked: signIn.focusInput()

    SignInBox {
        id: signIn
        anchors.horizontalCenter: parent.horizontalCenter
        picture: StartMenuState.picture
        name: StartMenuState.displayName
        message: LockState.error
        busy: LockState.busy
        text: LockState.typed
        onTextChanged: LockState.typed = text
        onSubmitted: LockState.submit()
    }
}
