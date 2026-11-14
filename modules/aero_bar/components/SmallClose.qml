import QtQuick
import "../../../utils/colors.js" as ColorUtils

Item {
    id: root

    property bool lit: false
    property real radius: 3

    signal clicked

    readonly property bool hovered: mouse.containsMouse

    readonly property alias hoverT: hp.hoverT
    readonly property alias pressedT: hp.pressedT
    readonly property real shownT: lit ? 1 : hoverT
    readonly property color glyphColor: ColorUtils.interpolateColors("#5b6470", "white", shownT)

    implicitWidth: 16
    implicitHeight: 15

    HoverPress {
        id: hp
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        opacity: root.shownT
        visible: opacity > 0
        border.width: 1
        border.color: Qt.rgba(0.35, 0, 0, 0.7)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: hp.shade("#e9a99a", "#f3a493", "#d98a78")
            }
            GradientStop {
                position: 0.5
                color: hp.shade("#c8462a", "#d9563b", "#a8301a")
            }
            GradientStop {
                position: 1
                color: hp.shade("#d7704f", "#c63a1c", "#a83014")
            }
        }
    }

    // plain bars, not a Canvas: cheap enough for every overview window
    component Bar: Rectangle {
        width: 9
        height: 1.6
        radius: 0.8
        antialiasing: true
    }

    Bar {
        anchors.centerIn: parent
        rotation: 45
        color: root.glyphColor
    }

    Bar {
        anchors.centerIn: parent
        rotation: -45
        color: root.glyphColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
