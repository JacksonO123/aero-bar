import QtQuick
import QtQuick.Effects

// the glow is a blurred copy underneath, so the label stays unlayered and crisp
Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property real glow: 0.7
    property alias elide: label.elide

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        x: label.x
        y: label.y
        width: label.width
        text: label.text
        font: label.font
        elide: label.elide
        color: "black"
        opacity: root.glow

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.5
            blurMax: 6
        }
    }

    Text {
        id: label
        width: root.width
        color: "white"
        font.pixelSize: 12
    }
}
