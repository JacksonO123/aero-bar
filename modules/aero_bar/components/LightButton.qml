import QtQuick
import "../../../utils/colors.js" as ColorUtils

// Windows 7 push button for light surfaces (flyout content): grey two-tone, blue when hot.
Item {
    id: root

    signal clicked(var mouse)
    default property alias content: contentArea.data

    property real radius: 3
    property bool checked: false

    property real hoverT: mouse.containsMouse ? 1 : 0
    property real pressedT: mouse.pressed || checked ? 1 : 0

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

    function mix(normal, hot, pressed) {
        return ColorUtils.interpolateColors(ColorUtils.interpolateColors(normal, hot, hoverT), pressed, pressedT);
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        border.width: 1
        border.color: root.mix("#707070", "#3c7fb1", "#2c628b")

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.mix("#f2f2f2", "#eaf6fd", "#e5f4fc")
            }
            GradientStop {
                position: 0.49
                color: root.mix("#ebebeb", "#d9f0fc", "#c4e5f6")
            }
            GradientStop {
                position: 0.5
                color: root.mix("#dddddd", "#bee6fd", "#98d1ef")
            }
            GradientStop {
                position: 1.0
                color: root.mix("#cfcfcf", "#a7d9f5", "#68b3db")
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
