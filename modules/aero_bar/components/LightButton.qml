import QtQuick

Item {
    id: root

    signal clicked(var mouse)
    default property alias content: contentArea.data

    property real radius: 3
    property bool checked: false

    readonly property alias hoverT: hp.hoverT
    readonly property alias pressedT: hp.pressedT

    HoverPress {
        id: hp
        hovered: mouse.containsMouse
        pressed: mouse.pressed || root.checked
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        border.width: 1
        border.color: hp.shade("#707070", "#3c7fb1", "#2c628b")

        gradient: SplitGradient {
            split: 0.49
            splitEnd: 0.5
            colors: {
                const top = hp.shade("#f2f2f2", "#eaf6fd", "#e5f4fc");
                const aboveSplit = hp.shade("#ebebeb", "#d9f0fc", "#c4e5f6");
                const belowSplit = hp.shade("#dddddd", "#bee6fd", "#98d1ef");
                const bottom = hp.shade("#cfcfcf", "#a7d9f5", "#68b3db");
                return [top, aboveSplit, belowSplit, bottom];
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.7 * (1 - root.pressedT * 0.6))
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
    }
}
