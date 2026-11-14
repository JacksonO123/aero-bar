import QtQuick
import QtQuick.Effects

Item {
    id: root

    property color color: "#46c4ff"
    property real radius: 0
    property int spread: 10
    property real grow: 2

    // the layer clips the blur, so give it room to spread
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
