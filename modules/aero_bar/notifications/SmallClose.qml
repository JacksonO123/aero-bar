import QtQuick

// The little x in a balloon or list row; a small red glass square under the pointer.
Item {
    id: root

    signal clicked

    readonly property bool hovered: mouse.containsMouse

    implicitWidth: 16
    implicitHeight: 15

    Rectangle {
        anchors.fill: parent
        radius: 3
        visible: mouse.containsMouse
        border.width: 1
        border.color: Qt.rgba(0.35, 0, 0, 0.7)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#f3a493"
            }
            GradientStop {
                position: 0.5
                color: "#d9563b"
            }
            GradientStop {
                position: 1
                color: "#c63a1c"
            }
        }
    }

    Canvas {
        anchors.centerIn: parent
        width: 8
        height: 8
        property bool lit: mouse.containsMouse
        onLitChanged: requestPaint()
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
            ctx.strokeStyle = lit ? "white" : "#5b6470";
            ctx.stroke();
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
