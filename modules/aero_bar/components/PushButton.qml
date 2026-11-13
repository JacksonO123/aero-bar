import QtQuick

// A Windows 7 push button: grey glass that turns pale blue under the pointer. `isDefault` marks
// the button Enter presses, which pulses slowly blue like Win7's default button.
Item {
    id: root

    property alias text: label.text
    property bool isDefault: false

    signal clicked

    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed && mouse.containsMouse

    property real hoverT: hovered ? 1 : 0
    property real pulse: 0

    implicitWidth: Math.max(78, label.implicitWidth + 26)
    implicitHeight: 24
    opacity: enabled ? 1 : 0.6

    Behavior on hoverT {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation on pulse {
        running: root.isDefault && root.enabled && root.visible && !root.hovered
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            to: 1
            duration: 1200
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 0
            duration: 1200
            easing.type: Easing.InOutSine
        }
    }

    component Face: Rectangle {
        property var stops: []

        anchors.fill: parent
        radius: 3
        gradient: Gradient {
            GradientStop {
                position: 0
                color: stops[0]
            }
            GradientStop {
                position: 0.48
                color: stops[1]
            }
            GradientStop {
                position: 0.5
                color: stops[2]
            }
            GradientStop {
                position: 1
                color: stops[3]
            }
        }
    }

    Face {
        stops: ["#f2f2f2", "#ebebeb", "#dddddd", "#cfcfcf"]
    }

    Face {
        stops: ["#eaf6fd", "#d9f0fc", "#bee6fd", "#a7d9f5"]
        opacity: Math.max(root.hoverT, root.isDefault ? root.pulse * 0.75 : 0)
    }

    Face {
        stops: ["#e5f4fc", "#c4e5f6", "#98d1ef", "#68b3db"]
        opacity: root.pressed ? 1 : 0
    }

    // inner highlight, then the outline
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: root.pressed ? Qt.rgba(0, 0.1, 0.25, 0.25) : Qt.rgba(1, 1, 1, 0.8)
    }

    Rectangle {
        anchors.fill: parent
        radius: 3
        color: "transparent"
        border.width: 1
        border.color: root.pressed ? "#2c628b" : (root.hovered || root.isDefault) ? "#3c7fb1" : "#707070"
    }

    Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.pressed ? 1 : 0
        color: root.enabled ? "#1a1a1a" : "#838383"
        font.pixelSize: 12
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
