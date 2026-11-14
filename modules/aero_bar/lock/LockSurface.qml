import QtQuick
import "../session"
import "../../../services"

Item {
    anchors.fill: parent

    LogonScreen {
        power: StartMenuState
        shown: !SessionEnd.active
        onBackgroundClicked: signIn.focusInput()
        onShownChanged: {
            if (shown) {
                signIn.focusInput();
            }
        }

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

    // layer surfaces don't show over a session lock
    SessionEndView {}
}
