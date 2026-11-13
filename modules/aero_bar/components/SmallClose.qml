import QtQuick

// The little x on balloons, list rows and taskbar thumbnails: a small red glass square under
// the pointer. `lit` keeps the red square showing (dimmer) even when not hovered.
Item {
    id: root

    property bool lit: false

    signal clicked

    readonly property bool hovered: mouse.containsMouse

    implicitWidth: 16
    implicitHeight: 15

    Rectangle {
        anchors.fill: parent
        radius: 3
        visible: root.lit || mouse.containsMouse
        border.width: 1
        border.color: Qt.rgba(0.35, 0, 0, 0.7)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: mouse.containsMouse ? "#f3a493" : "#e9a99a"
            }
            GradientStop {
                position: 0.5
                color: mouse.containsMouse ? "#d9563b" : "#c8462a"
            }
            GradientStop {
                position: 1
                color: mouse.containsMouse ? "#c63a1c" : "#d7704f"
            }
        }
    }

    Canvas {
        anchors.centerIn: parent
        width: 8
        height: 8
        property bool white: root.lit || mouse.containsMouse
        onWhiteChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.beginPath();
            ctx.moveTo(1, 1);
            ctx.lineTo(7, 7);
            ctx.moveTo(7, 1);
            ctx.lineTo(1, 7);
            ctx.lineWidth = 1.6;
            ctx.lineCap = "round";
            ctx.strokeStyle = white ? "white" : "#5b6470";
            ctx.stroke();
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
