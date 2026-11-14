import QtQuick

Item {
    id: root

    property real radius: 0
    property color outerColor: Qt.rgba(0, 0, 0, 0.6)
    property color innerColor: Qt.rgba(1, 1, 1, 0.35)
    property bool outlineOnTop: false

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: root.outerColor
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        z: root.outlineOnTop ? -1 : 0
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: root.innerColor
    }
}
