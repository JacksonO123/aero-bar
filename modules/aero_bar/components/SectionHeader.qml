import QtQuick

Item {
    id: root

    property alias text: label.text
    property color color: "#1e5aa8"

    implicitWidth: 200
    implicitHeight: 18

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        color: root.color
        font.pixelSize: 11
    }

    Rectangle {
        anchors.left: label.right
        anchors.leftMargin: 7
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        height: 1

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: Qt.rgba(0.6, 0.72, 0.85, 1)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0.6, 0.72, 0.85, 0)
            }
        }
    }
}
