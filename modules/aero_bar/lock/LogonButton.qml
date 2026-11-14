import QtQuick
import "../components"

Item {
    id: root

    property alias text: label.text

    signal clicked

    readonly property alias hoverT: hp.hoverT
    readonly property alias pressedT: hp.pressedT

    implicitWidth: label.implicitWidth + 44
    implicitHeight: 30

    HoverPress {
        id: hp
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Rectangle {
        anchors.fill: parent
        radius: 3
        border.width: 1
        border.color: Qt.rgba(0, 0.05, 0.15, 0.55)

        gradient: SplitGradient {
            split: 0.48
            splitEnd: 0.5
            colors: {
                const h = root.hoverT, p = root.pressedT;
                const top = Qt.rgba(1, 1, 1, 0.3 + 0.15 * h - 0.15 * p);
                const aboveSplit = Qt.rgba(1, 1, 1, 0.14 + 0.12 * h - 0.08 * p);
                const belowSplit = Qt.rgba(0, 0.08, 0.25, 0.12 + 0.1 * p);
                const bottom = Qt.rgba(1, 1, 1, 0.1 + 0.12 * h);
                return [top, aboveSplit, belowSplit, bottom];
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.45 + 0.3 * root.hoverT)
        }
    }

    CaptionText {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.pressedT > 0.5 ? 1 : 0
        font.pixelSize: 14
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
