import QtQuick
import "../../../services"

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
