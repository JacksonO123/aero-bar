import QtQuick
import "../components"

Item {
    id: root

    property alias text: field.text
    property alias placeholder: field.placeholder
    property alias echoMode: field.echoMode
    property bool busy: false

    signal submitted

    function focusInput() {
        field.focusInput();
    }

    width: 280
    height: 34

    Row {
        anchors.centerIn: parent
        spacing: 8
        visible: !root.busy

        TextField {
            id: field
            autoFocus: true
            width: 236
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            fontSize: 14
            placeholder: "Password"
            echoMode: TextInput.Password
            onAccepted: root.submitted()
            Keys.onEscapePressed: clear()
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
                onClicked: root.submitted()
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 10
        visible: root.busy

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
