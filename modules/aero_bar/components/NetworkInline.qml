import QtQuick
import "../flyout"
import "../../../services"

// Network icon in the taskbar. Click for the network flyout.
Win7Frame {
    id: root

    required property Flyout flyoutEl
    property bool active: false

    implicitWidth: 30
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    frameOpacity: Math.max(hoverT, active ? 1 : 0)
    onClicked: flyoutEl.toggle(root)

    Win7Hover {
        radius: root.radius
        opacity: Math.max(root.hoverT, root.active ? 0.8 : 0)
        pressedT: root.pressedT
    }

    NetworkGlyph {
        anchors.centerIn: parent
        width: 20
        height: 18
        kind: NetState.kind
        strength: NetState.strength
        badge: NetState.badge
    }
}
