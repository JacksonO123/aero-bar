import QtQuick

Item {
    id: root
    property int radius: 4
    signal clicked(var mouse)
    default property alias content: contentArea.data
    // drawn above the frame's own click area, for controls that need their own clicks
    property alias overlay: overlayArea.data

    // from a HoverHandler, so the frame stays hovered over controls inside it (e.g. the overlay)
    readonly property bool hovered: hoverHandler.hovered
    readonly property alias hoverT: hp.hoverT
    readonly property alias pressedT: hp.pressedT

    property real frameOpacity

    HoverPress {
        id: hp
        hovered: root.hovered
        pressed: mouse.pressed
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
    }

    Item {
        id: overlayArea
        anchors.fill: parent
    }

    HoverHandler {
        id: hoverHandler
    }
}
