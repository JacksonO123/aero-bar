import Quickshell.Widgets
import QtQuick
import Qt5Compat.GraphicalEffects

ClippingRectangle {
    id: root

    required property real pressedT

    anchors.fill: parent
    color: "transparent"

    RadialGradient {
        anchors.fill: parent
        horizontalOffset: -parent.width * 0.25
        verticalOffset: -parent.height / 2
        horizontalRadius: parent.width * 0.75 * Math.SQRT2
        verticalRadius: parent.height * Math.SQRT2

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(1, 1, 1, 0.38 + (0.1 * root.pressedT))
            }
            GradientStop {
                position: 0.6
                color: Qt.rgba(1, 1, 1, 0.04 + (0.1 * root.pressedT))
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, 0.12 + (0.1 * root.pressedT))
            }
        }
    }
}
