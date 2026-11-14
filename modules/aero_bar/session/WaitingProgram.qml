import QtQuick
import "../components"
import "../lock"
import "../../../services"

Item {
    id: root

    required property var toplevel
    property bool divided: false

    readonly property string appId: Taskbar.appIdOf(toplevel)

    Rectangle {
        id: tile
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        radius: 7
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.5)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(1, 1, 1, 0.38)
            }
            GradientStop {
                position: 0.5
                color: Qt.rgba(1, 1, 1, 0.14)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0.6, 0.85, 1, 0.22)
            }
        }

        ImageIcon {
            id: icon
            anchors.centerIn: parent
            wmClass: root.appId
            size: 28
        }
    }

    Column {
        anchors.left: tile.right
        anchors.leftMargin: 14
        anchors.right: spinner.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            id: name
            width: parent.width
            elide: Text.ElideRight
            text: icon.entry?.name || root.appId || root.toplevel?.title || "Program"
            color: "white"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: text !== "" && text !== name.text
            text: root.toplevel?.title ?? ""
            color: Qt.rgba(1, 1, 1, 0.72)
            font.pixelSize: 12
        }
    }

    BusyCircle {
        id: spinner
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        size: 18
    }

    Rectangle {
        anchors.bottom: parent.bottom
        x: 6
        width: parent.width - 12
        height: 1
        color: Qt.rgba(1, 1, 1, 0.12)
        visible: root.divided
    }
}
