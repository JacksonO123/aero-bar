import QtQuick

// A Windows 7 text box: white, slightly recessed, blue border while focused.
Item {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""
    property real fontSize: 12
    // take the keyboard whenever it appears (or is created already showing)
    property bool autoFocus: false
    readonly property bool focused: input.activeFocus

    signal accepted

    function focusInput() {
        input.forceActiveFocus();
    }

    function focusIfAuto() {
        if (autoFocus && visible) {
            focusInput();
        }
    }

    onVisibleChanged: focusIfAuto()
    Component.onCompleted: focusIfAuto()

    implicitWidth: 180
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: 2
        border.width: 1
        border.color: root.focused ? "#3d7bad" : mouseArea.containsMouse ? "#5794bf" : "#abadb3"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#eef1f4"
            }
            GradientStop {
                position: 0.12
                color: "#ffffff"
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => {
            input.forceActiveFocus();
            mouse.accepted = false;
        }
    }

    TextInput {
        id: input
        x: 6
        width: parent.width - 12
        anchors.verticalCenter: parent.verticalCenter
        color: "#1a1a1a"
        selectionColor: "#3399ff"
        selectedTextColor: "white"
        font.pixelSize: root.fontSize
        passwordCharacter: "●"
        clip: true
        onAccepted: root.accepted()

        Text {
            anchors.verticalCenter: parent.verticalCenter
            // like Win7's cue banners, the hint stays until you type
            visible: input.text === ""
            text: root.placeholder
            color: "#8a8a8a"
            font.pixelSize: root.fontSize
            font.italic: true
        }
    }
}
