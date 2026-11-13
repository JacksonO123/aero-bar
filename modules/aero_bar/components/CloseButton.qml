import QtQuick

// The red Windows 7 caption close button. It hangs from the top edge of a glass frame.
Item {
    id: root

    signal clicked

    property real hoverT: mouse.containsMouse ? 1 : 0

    implicitWidth: 43
    implicitHeight: 19

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    component Face: Rectangle {
        id: face

        property var colors: []

        anchors.fill: parent
        radius: 4
        gradient: SplitGradient {
            split: 0.45
            splitEnd: 0.5
            colors: face.colors
        }
    }

    // square top corners: it is attached to the frame's top edge
    Item {
        anchors.fill: parent
        clip: true

        Item {
            width: parent.width
            height: parent.height + 4
            y: -4

            Face {
                colors: ["#e9a99a", "#d8705a", "#c0391c", "#d9733f"]
            }
            Face {
                colors: ["#f7c4b6", "#ef8c70", "#e8401a", "#f59a5e"]
                opacity: root.hoverT
            }
            Face {
                colors: ["#c97060", "#b0402a", "#8e1d06", "#c45a2c"]
                opacity: mouse.pressed ? 1 : 0
            }
            Bevel {
                anchors.fill: parent
                radius: 4
                outerColor: Qt.rgba(0.25, 0, 0, 0.75)
                innerColor: Qt.rgba(1, 1, 1, 0.45 + 0.2 * root.hoverT)
            }
        }
    }

    // the cross, white with a dark outline
    Canvas {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: mouse.pressed ? 1 : 0
        width: 12
        height: 11
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const d = 3;
            const cross = () => {
                ctx.beginPath();
                ctx.moveTo(d, d - 0.5);
                ctx.lineTo(width - d, height - d + 0.5);
                ctx.moveTo(width - d, d - 0.5);
                ctx.lineTo(d, height - d + 0.5);
            };
            ctx.lineCap = "round";
            cross();
            ctx.strokeStyle = "rgba(70,0,0,0.7)";
            ctx.lineWidth = 4;
            ctx.stroke();
            cross();
            ctx.strokeStyle = "white";
            ctx.lineWidth = 2;
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
