import QtQuick

// A Windows 7 check box with its label.
Item {
    id: root

    property bool checked: false
    property alias text: label.text

    signal toggled(bool checked)

    implicitWidth: box.width + 7 + label.implicitWidth
    implicitHeight: Math.max(box.height, label.implicitHeight)

    Rectangle {
        id: box
        width: 13
        height: 13
        anchors.verticalCenter: parent.verticalCenter
        border.width: 1
        border.color: mouse.containsMouse ? "#3c7fb1" : "#8f8f8f"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: mouse.containsMouse ? "#dff2fc" : "#e4e4e4"
            }
            GradientStop {
                position: 1
                color: mouse.containsMouse ? "#f4fbfe" : "#fbfbfb"
            }
        }

        Canvas {
            anchors.fill: parent
            visible: root.checked
            onVisibleChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.beginPath();
                ctx.moveTo(3, 6.5);
                ctx.lineTo(5.5, 9);
                ctx.lineTo(10, 3.5);
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.strokeStyle = "#1c4e8c";
                ctx.stroke();
            }
        }
    }

    Text {
        id: label
        x: box.width + 7
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 12
        color: "#1a1a1a"
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
