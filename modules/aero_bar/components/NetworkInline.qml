import QtQuick
import "../../../services"

// Network icon in the taskbar. Click for the network flyout.
FlyoutButton {
    NetworkGlyph {
        anchors.centerIn: parent
        width: 20
        height: 18
        kind: NetState.kind
        strength: NetState.strength
        badge: NetState.badge
    }
}
