import QtQuick
import QtQuick.Effects

// Frutiger Aero's halo: a soft coloured glow around a rounded rectangle the size of this item
// (grown by `grow` px), spreading `spread` px outside it. Lay it under the thing that glows,
// filling it.
Item {
    id: root

    property color color: "#46c4ff"
    property real radius: 0
    property int spread: 12
    property real grow: 2

    // room around the shape for the blur to spread into
    Item {
        anchors.fill: parent
        anchors.margins: -root.spread

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: root.spread
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.spread - root.grow
            radius: root.radius + root.grow
            color: root.color
        }
    }
}
