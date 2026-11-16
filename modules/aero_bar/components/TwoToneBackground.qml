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
    property real tintStrength: 1.0
    property real bodyAlpha: 0.75

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
                color: Qt.rgba(0.5, 0.5, 0.5, root.bodyAlpha)
            }
            GradientStop {
                position: 0.5
                color: Qt.rgba(0.2, 0.2, 0.2, root.bodyAlpha)
            }
            GradientStop {
                position: 0.500001
                color: Qt.rgba(root.darkRGBColor, root.darkRGBColor, root.darkRGBColor, root.bodyAlpha)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.barTint.r, Theme.barTint.g, Theme.barTint.b, Theme.barTint.a * root.tintStrength)

        Behavior on color {
            ColorAnimation {
                duration: 250
            }
        }
    }
}
