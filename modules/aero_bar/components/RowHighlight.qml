import QtQuick

import "../../../utils/colors.js" as ColorUtils

Rectangle {
    id: root

    property bool hot: false
    property bool selected: false
    property bool glass: false

    property color hotColor: "#e5f3fb"
    property color hotBorderColor: "#b8d6fb"
    property color selectedColor: "#dcebfc"
    property color selectedBorderColor: "#7da2ce"

    radius: 3
    color: selected ? selectedColor : hotColor
    border.width: 1
    border.color: selected ? selectedBorderColor : hotBorderColor
    opacity: hot || selected ? 1 : 0
    visible: opacity > 0
    gradient: glass ? sheen : null

    Gradient {
        id: sheen

        GradientStop {
            position: 0
            color: ColorUtils.interpolateColors(root.color, "white", 0.6)
        }
        GradientStop {
            position: 1
            color: root.color
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        visible: root.glass
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.7)
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 110
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 110
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 110
        }
    }
}
