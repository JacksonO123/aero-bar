import QtQuick

Item {
    id: root
    property int radius: 4
    signal clicked
    default property alias content: contentArea.data

    property real hoverT: mouse.containsMouse ? 1 : 0
    property real pressedT: mouse.pressed ? 1 : 0

    property real frameOpacity

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]
        }
    }

    Behavior on pressedT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.35 * root.frameOpacity)
    }

    Rectangle {
        y: 1
        height: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.radius
        anchors.rightMargin: root.radius
        color: Qt.rgba(1, 1, 1, 0.55 * root.frameOpacity)
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.6 * root.frameOpacity)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
