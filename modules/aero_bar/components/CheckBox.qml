import QtQuick
import "../../../utils/colors.js" as ColorUtils

// A Windows 7 check box with its label. Controlled: bind `checked`, handle `toggled`.
Item {
    id: root

    property bool checked: false
    property alias text: label.text

    signal toggled(bool checked)

    property real hoverT: mouse.containsMouse ? 1 : 0
    property real pressedT: mouse.pressed ? 1 : 0

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

    // a colour at rest, under the pointer and pressed
    function shade(rest, hot, pressed) {
        return ColorUtils.interpolateColors(ColorUtils.interpolateColors(rest, hot, hoverT), pressed, pressedT);
    }

    implicitWidth: box.width + 7 + label.implicitWidth
    implicitHeight: Math.max(box.height, label.implicitHeight)

    Rectangle {
        id: box
        width: 13
        height: 13
        anchors.verticalCenter: parent.verticalCenter
        border.width: 1
        border.color: root.shade("#8f8f8f", "#3c7fb1", "#2c628b")
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.shade("#e4e4e4", "#dff2fc", "#c2e4f6")
            }
            GradientStop {
                position: 1
                color: root.shade("#fbfbfb", "#f4fbfe", "#e9f7fe")
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
        // doesn't set `checked` itself: callers bind it to their state and update that state
        // from `toggled`, so the box keeps following changes made elsewhere
        onClicked: root.toggled(!root.checked)
    }
}
