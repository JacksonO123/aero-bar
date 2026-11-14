import QtQuick
import "../../../services"

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
