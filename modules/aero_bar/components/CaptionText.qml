import QtQuick
import QtQuick.Effects

// White caption text on glass with Win7's soft dark glow behind it. The glow is a blurred copy
// drawn underneath, so the text itself stays unlayered and crisp.
Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property real glow: 0.7

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        x: label.x
        y: label.y
        text: label.text
        font: label.font
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
        color: "white"
        font.pixelSize: 12
    }
}
