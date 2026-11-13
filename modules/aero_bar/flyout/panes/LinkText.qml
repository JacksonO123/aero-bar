import QtQuick

// A Win7 blue link.
Text {
    id: root

    signal clicked

    color: mouse.containsMouse ? "#3399ff" : "#1c5ea8"
    font.pixelSize: 12
    font.underline: mouse.containsMouse

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
