import QtQuick

Item {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""
    property real fontSize: 12
    property bool autoFocus: false
    readonly property bool focused: input.activeFocus

    signal accepted

    // unlike assigning text, keeps a binding on `text`
    function clear() {
        input.clear();
    }

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

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }
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
            visible: input.text === ""
            text: root.placeholder
            color: "#8a8a8a"
            font.pixelSize: root.fontSize
            font.italic: true
        }
    }
}
