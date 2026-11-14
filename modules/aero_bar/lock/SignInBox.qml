import QtQuick
import "../components"

Column {
    id: root

    property string picture: ""
    property string name: ""
    property string message: ""
    property bool busy: false

    property alias text: password.text
    property alias placeholder: password.placeholder
    property alias echoMode: password.echoMode

    signal submitted

    function focusInput() {
        password.focusInput();
    }

    spacing: 14

    ProfileTile {
        anchors.horizontalCenter: parent.horizontalCenter
        size: 168
        bezel: 11
        cornerRadius: 18
        bow: 3.2
        pictureRadius: 5
        picture: root.picture
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.name
        font.pixelSize: 28
        glow: 0.8
    }

    PasswordBox {
        id: password
        anchors.horizontalCenter: parent.horizontalCenter
        busy: root.busy
        onSubmitted: root.submitted()
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: text !== ""
        text: root.message
        font.pixelSize: 14
    }
}
