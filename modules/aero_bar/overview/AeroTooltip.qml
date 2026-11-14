import QtQuick

// Windows 7 tooltip: pale gradient, thin grey border, soft shadow.
Item {
    id: root

    property string text: ""
    property bool shown: false

    width: label.implicitWidth + 14
    height: label.implicitHeight + 8
    opacity: shown && text !== "" ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 120
        }
    }

    Rectangle {
        x: 1
        y: 2
        width: parent.width
        height: parent.height
        radius: 3
        color: Qt.rgba(0, 0, 0, 0.3)
    }

    Rectangle {
        anchors.fill: parent
        radius: 3
        border.width: 1
        border.color: "#767676"

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#ffffff"
            }
            GradientStop {
                position: 1.0
                color: "#e4e5f0"
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "#4c4c4c"
        font.pixelSize: 11
    }
}
