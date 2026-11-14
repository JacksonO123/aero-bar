import QtQuick
import Quickshell.Bluetooth

FlyoutButton {
    visible: Bluetooth.defaultAdapter !== null
    implicitWidth: visible ? 30 : 0

    BluetoothGlyph {
        anchors.centerIn: parent
        size: 18
        off: !(Bluetooth.defaultAdapter?.enabled ?? false)
    }
}
