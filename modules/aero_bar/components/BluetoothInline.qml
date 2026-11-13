import QtQuick
import Quickshell.Bluetooth
import "../flyout"

// Bluetooth orb in the taskbar (only when there is an adapter). Click for the device flyout.
Win7Frame {
    id: root

    required property Flyout flyoutEl
    property bool active: false

    visible: Bluetooth.defaultAdapter !== null
    implicitWidth: visible ? 30 : 0
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

    BluetoothGlyph {
        anchors.centerIn: parent
        size: 18
        off: !(Bluetooth.defaultAdapter?.enabled ?? false)
    }
}
