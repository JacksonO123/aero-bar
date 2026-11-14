import QtQuick

Text {
    id: root

    property color restColor: "#1c5ea8"
    property bool underlineOnHover: true
    readonly property bool hovered: mouse.containsMouse

    signal clicked

    color: hovered ? "#3399ff" : restColor
    font.pixelSize: 12
    font.underline: underlineOnHover && hovered

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
