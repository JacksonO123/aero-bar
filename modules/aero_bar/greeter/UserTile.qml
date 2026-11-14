import QtQuick
import "../components"

// One account on the login screen's "choose a user" row: its framed picture with the name
// underneath. The frame lights up under the pointer.
Item {
    id: root

    property string name: ""
    property string picture: ""

    signal clicked

    implicitWidth: Math.max(tile.width, label.implicitWidth)
    implicitHeight: tile.height + 12 + label.implicitHeight

    ProfileTile {
        id: tile
        anchors.horizontalCenter: parent.horizontalCenter
        size: 126
        bezel: 9
        cornerRadius: 14
        bow: 2.6
        pictureRadius: 4
        picture: root.picture
        hoverT: mouse.containsMouse ? 1 : 0
    }

    CaptionText {
        id: label
        anchors.horizontalCenter: parent.horizontalCenter
        y: tile.height + 12
        text: root.name
        font.pixelSize: 18
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
