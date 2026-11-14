import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    required property Item target
    property real fraction: 0.35
    property real strength: 0.35

    width: target ? target.width : 0
    height: target ? target.height * fraction : 0
    clip: true

    Item {
        id: flipped
        width: root.width
        height: root.target ? root.target.height : 0
        opacity: root.strength

        transform: Scale {
            origin.y: flipped.height / 2
            yScale: -1
        }

        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: root.target
            hideSource: false
            live: true
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: fade
        }
    }

    // the mask applies before the flip, so its opaque bottom shows at the top
    Rectangle {
        id: fade
        width: flipped.width
        height: flipped.height
        visible: false

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                position: Math.max(0, 1 - root.fraction)
                color: "transparent"
            }
            GradientStop {
                position: 1.0
                color: "black"
            }
        }
    }
}
