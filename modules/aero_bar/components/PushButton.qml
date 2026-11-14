import QtQuick
import "../../../utils/colors.js" as ColorUtils

// A Windows 7 push button: grey glass that turns pale blue under the pointer. `isDefault` marks
// the button Enter presses, which pulses slowly blue like Win7's default button.
Item {
    id: root

    property alias text: label.text
    property bool isDefault: false

    signal clicked

    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed && mouse.containsMouse

    readonly property alias hoverT: hp.hoverT
    readonly property alias pressedT: hp.pressedT
    property real pulse: 0

    HoverPress {
        id: hp
        hovered: root.hovered
        pressed: root.pressed
        hoverDuration: 160
    }

    implicitWidth: Math.max(78, label.implicitWidth + 26)
    implicitHeight: 24
    opacity: enabled ? 1 : 0.6

    // (dialogs stay loaded while hidden: only pulse while the window is up)
    SequentialAnimation on pulse {
        running: root.isDefault && root.enabled && root.visible && (root.Window.window?.visible ?? false) && !root.hovered
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
        id: face

        property var colors: []

        anchors.fill: parent
        radius: 3
        gradient: SplitGradient {
            split: 0.48
            splitEnd: 0.5
            colors: face.colors
        }
    }

    Face {
        colors: ["#f2f2f2", "#ebebeb", "#dddddd", "#cfcfcf"]
    }

    Face {
        colors: ["#eaf6fd", "#d9f0fc", "#bee6fd", "#a7d9f5"]
        opacity: Math.max(root.hoverT, root.isDefault ? root.pulse * 0.75 : 0)
    }

    Face {
        colors: ["#e5f4fc", "#c4e5f6", "#98d1ef", "#68b3db"]
        opacity: root.pressedT
    }

    // the outline turns blue with the hover glow (the default button's stays blue)
    Bevel {
        anchors.fill: parent
        radius: 3
        outerColor: ColorUtils.interpolateColors(ColorUtils.interpolateColors("#707070", "#3c7fb1", root.isDefault ? 1 : root.hoverT), "#2c628b", root.pressedT)
        innerColor: ColorUtils.interpolateColors(Qt.rgba(1, 1, 1, 0.8), Qt.rgba(0, 0.1, 0.25, 0.25), root.pressedT)
        outlineOnTop: true
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
