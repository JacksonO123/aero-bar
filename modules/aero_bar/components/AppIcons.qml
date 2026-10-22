import Quickshell.Widgets
import QtQuick.Layouts
import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects

Repeater {
    id: repeater
    required property var apps
    model: repeater.apps

    AppIconFrame {
        id: entry

        required property var modelData

        Layout.fillHeight: true
        implicitWidth: 62
        onClicked: Quickshell.execDetached(entry.modelData.cmd)
        frameOpacity: entry.hoverT

        Image {
            id: appImage
            property int size: entry.modelData.size

            anchors.centerIn: parent
            anchors.verticalCenterOffset: entry.modelData.offset

            source: entry.modelData.img
            sourceSize: Qt.size(width * 2, height * 2)
            width: size
            height: size * 2
        }

        ClippingRectangle {
            anchors.fill: parent
            radius: entry.radius
            color: "transparent"
            opacity: entry.hoverT

            RadialGradient {
                anchors.fill: parent
                horizontalOffset: -entry.width * 0.25
                verticalOffset: -entry.height / 2
                horizontalRadius: entry.width * 0.75 * Math.SQRT2
                verticalRadius: entry.height * Math.SQRT2

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(1, 1, 1, 0.38 + (0.1 * entry.pressedT))
                    }
                    GradientStop {
                        position: 0.6
                        color: Qt.rgba(1, 1, 1, 0.04 + (0.1 * entry.pressedT))
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(1, 1, 1, 0.12 + (0.1 * entry.pressedT))
                    }
                }
            }
        }
    }
}
