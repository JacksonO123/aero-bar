import QtQuick

// "Search programs and files" field: white, slightly recessed, magnifier on the right.
Item {
    id: root

    property alias text: input.text
    readonly property bool focused: input.activeFocus

    function focusInput() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
    }

    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: 3
        border.width: 1
        border.color: root.focused ? "#3d7bad" : "#8a9bab"

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

    TextInput {
        id: input
        x: 9
        width: parent.width - x - 30
        anchors.verticalCenter: parent.verticalCenter
        color: "#1a1a1a"
        selectionColor: "#3399ff"
        selectedTextColor: "white"
        font.pixelSize: 12
        clip: true

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: "Search programs and files"
            color: "#8a8a8a"
            font.pixelSize: 12
            font.italic: true
        }
    }

    // the asset carries its own reflection underneath; show the top half
    Image {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 17
        height: 17
        source: Qt.resolvedUrl("../../../assets/magnifying-glass-icon-reflect.png")
        fillMode: Image.PreserveAspectCrop
        verticalAlignment: Image.AlignTop
        sourceSize.width: 40
        mipmap: true
        opacity: input.text === "" ? 0.85 : 1
    }
}
