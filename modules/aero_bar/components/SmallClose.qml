import QtQuick
import "../../../utils/colors.js" as ColorUtils

// The little x on balloons, list rows and taskbar thumbnails: a small red glass square under
// the pointer. `lit` keeps the red square showing (dimmer) even when not hovered.
Item {
    id: root

    property bool lit: false
    property real radius: 3

    signal clicked

    readonly property bool hovered: mouse.containsMouse

    property real hoverT: hovered ? 1 : 0
    property real pressedT: mouse.pressed ? 1 : 0

    implicitWidth: 16
    implicitHeight: 15

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

    // resting (lit), hot and pressed colour at one stop of the glass
    function shade(rest, hot, pressed) {
        return ColorUtils.interpolateColors(ColorUtils.interpolateColors(rest, hot, hoverT), pressed, pressedT);
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        opacity: Math.max(root.lit ? 1 : 0, root.hoverT)
        visible: opacity > 0
        border.width: 1
        border.color: Qt.rgba(0.35, 0, 0, 0.7)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.shade("#e9a99a", "#f3a493", "#d98a78")
            }
            GradientStop {
                position: 0.5
                color: root.shade("#c8462a", "#d9563b", "#a8301a")
            }
            GradientStop {
                position: 1
                color: root.shade("#d7704f", "#c63a1c", "#a83014")
            }
        }
    }

    // the x: two plain rotated bars (cheap enough for every overview window)
    component Bar: Rectangle {
        width: 9
        height: 1.6
        radius: 0.8
        antialiasing: true
    }

    Bar {
        anchors.centerIn: parent
        rotation: 45
        color: ColorUtils.interpolateColors("#5b6470", "white", Math.max(root.lit ? 1 : 0, root.hoverT))
    }

    Bar {
        anchors.centerIn: parent
        rotation: -45
        color: ColorUtils.interpolateColors("#5b6470", "white", Math.max(root.lit ? 1 : 0, root.hoverT))
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
