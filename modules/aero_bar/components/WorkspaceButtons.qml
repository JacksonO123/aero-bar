import QtQuick
import Quickshell.Hyprland
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../utils/colors.js" as ColorUtils

RowLayout {
    spacing: 8
    Repeater {
        id: workspaceButtonsRepeater
        model: Hyprland.workspaces

        AppIconFrame {
            id: frame

            required property var modelData
            property real isActive: frame.modelData.active
            property real hasContent: frame.modelData.toplevels.values.length

            Behavior on isActive {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutSine
                }
            }

            Behavior on hasContent {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutSine
                }
            }

            scale: 1 - (0.05 * frame.pressedT)

            implicitWidth: 46 + (frame.isActive * 12)
            implicitHeight: 22
            frameOpacity: 2 + frame.pressedT + (frame.hoverT / 2)

            onClicked: frame.modelData.activate()

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: frame.radius
                color: Qt.rgba(0.38, 0.56, 0.64, frame.isActive / 1.6)
            }

            ClippingRectangle {
                id: workspaceButton

                anchors.fill: parent
                color: Qt.rgba(1, 1, 1, 0.2 * frame.hoverT + 0.15 * frame.pressedT)
                radius: frame.radius

                TwoToneBackground {
                    type: "foreground"
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: height / 2
                    anchors.centerIn: parent
                    color: ColorUtils.interpolateColors("gray", "white", frame.hasContent)
                }
            }
        }
    }
}
