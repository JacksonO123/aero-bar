import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import "../../../services"

ClippingRectangle {
    id: root

    /// foreground/background
    property var type
    property var isHighContrast: type === "foreground"
    property var darkRGBColor: isHighContrast ? 0.03 : 0.1

    anchors.fill: parent
    color: "transparent"

    LinearGradient {
        anchors.fill: parent
        start: Qt.point(0, 0)
        end: Qt.point(0, height)

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(1, 1, 1, 1)
            }
            GradientStop {
                position: 0.03
                color: Qt.rgba(0.5, 0.5, 0.5, 0.75)
            }
            GradientStop {
                position: 0.5
                color: Qt.rgba(0.2, 0.2, 0.2, 0.75)
            }
            GradientStop {
                position: 0.500001
                color: Qt.rgba(root.darkRGBColor, root.darkRGBColor, root.darkRGBColor, 0.75)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.barTint

        Behavior on color {
            ColorAnimation {
                duration: 250
            }
        }
    }
}
