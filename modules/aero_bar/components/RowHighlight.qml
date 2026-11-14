import QtQuick

// Win7's hot-track behind a list row: pale blue under the pointer, a deeper blue when selected.
// Fades in and out like the rest of the shell's hover states.
Rectangle {
    id: root

    property bool hot: false
    property bool selected: false

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
