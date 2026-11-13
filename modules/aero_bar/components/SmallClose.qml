import QtQuick

// The little x on balloons, list rows and taskbar thumbnails: a small red glass square under
// the pointer. `lit` keeps the red square showing (dimmer) even when not hovered.
Item {
    id: root

    property bool lit: false
    property real radius: 3

    signal clicked

    readonly property bool hovered: mouse.containsMouse

    implicitWidth: 16
    implicitHeight: 15

    Rectangle {
        anchors.fill: parent
        radius: root.radius
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

    // the x: two plain rotated bars (cheap enough for every overview window)
    Repeater {
        model: [45, -45]

        Rectangle {
            required property real modelData
            anchors.centerIn: parent
            width: 9
            height: 1.6
            radius: 0.8
            rotation: modelData
            antialiasing: true
            color: root.lit || mouse.containsMouse ? "white" : "#5b6470"
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
