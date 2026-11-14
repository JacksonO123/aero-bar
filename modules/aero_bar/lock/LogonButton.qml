import QtQuick
import "../components"

// A button on the logon screen ("Switch User"): clear glass with a white edge and white text,
// brighter under the pointer, like Win7's.
Item {
    id: root

    property alias text: label.text

    signal clicked

    property real hoverT: mouse.containsMouse ? 1 : 0
    property real pressedT: mouse.pressed ? 1 : 0

    implicitWidth: label.implicitWidth + 44
    implicitHeight: 30

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Behavior on pressedT {
        NumberAnimation {
            duration: 80
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 3
        border.width: 1
        border.color: Qt.rgba(0, 0.05, 0.15, 0.55)

        gradient: SplitGradient {
            split: 0.48
            splitEnd: 0.5
            // clear glass, brighter under the pointer and a little darker pressed
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
