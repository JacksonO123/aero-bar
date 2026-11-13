import QtQuick
import Quickshell.Bluetooth

// Bluetooth orb in the taskbar (only when there is an adapter). Click for the device flyout.
FlyoutButton {
    visible: Bluetooth.defaultAdapter !== null
    implicitWidth: visible ? 30 : 0

    BluetoothGlyph {
        anchors.centerIn: parent
        size: 18
        off: !(Bluetooth.defaultAdapter?.enabled ?? false)
    }
}
