import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../components"
import "../../../../utils/constants.js" as Constants

// Bluetooth flyout: turn the adapter on or off, connect paired devices, and "Add a device" to
// search for new ones and pair them.
Item {
    id: root

    property bool shown: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var all: Bluetooth.devices.values
    readonly property var paired: all.filter(d => d.paired || d.bonded || d.connected).sort((a, b) => b.connected - a.connected)
    readonly property var found: all.filter(d => !(d.paired || d.bonded || d.connected) && d.name !== "")
    readonly property real padding: 12

    // a device being paired from "Add a device"; connect to it once it has paired. Kept here
    // because its row moves from "Available" to "Devices" when pairing finishes.
    property var pairing: null

    Connections {
        target: root.pairing
        ignoreUnknownSignals: true

        function onPairedChanged() {
            if (root.pairing?.paired) {
                root.pairing.connect();
                root.pairing = null;
            }
        }
    }

    width: 320
    height: content.height + padding * 2

    onShownChanged: {
        if (!shown && adapter?.discovering) {
            adapter.discovering = false;
        }
    }

    component DeviceRow: Item {
        id: row

        required property var modelData
        readonly property var d: modelData
        property bool pairRow: false

        signal pairRequested(var device)

        height: 38

        function statusOf(d) {
            if (d.pairing) {
                return "Pairing…";
            }
            if (d.state === BluetoothDeviceState.Connecting) {
                return "Connecting…";
            }
            if (d.state === BluetoothDeviceState.Disconnecting) {
                return "Disconnecting…";
            }
            if (d.connected) {
                return "Connected" + (d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "% battery" : "");
            }
            return "Paired";
        }

        Rectangle {
            anchors.fill: parent
            radius: 3
            visible: rowMouse.containsMouse
            color: "#e5f3fb"
            border.width: 1
            border.color: "#b8d6fb"
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
        }

        ImageIcon {
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            size: 24
            desktopIcon: row.d.icon || "bluetooth"
        }

        Column {
            x: 38
            width: parent.width - x - 96
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: row.d.name || row.d.address
                color: "#1a1a1a"
                font.pixelSize: 12
                font.bold: row.d.connected
                elide: Text.ElideRight
            }
            Text {
                text: row.pairRow ? (row.d.pairing ? "Pairing…" : "Ready to pair") : row.statusOf(row.d)
                color: "#6b7785"
                font.pixelSize: 11
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            LinkText {
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.pairRow && rowMouse.containsMouse
                text: "Remove"
                onClicked: row.d.forget()
            }

            PushButton {
                implicitWidth: 74
                implicitHeight: 22
                enabled: !row.d.pairing && row.d.state !== BluetoothDeviceState.Connecting && row.d.state !== BluetoothDeviceState.Disconnecting
                text: row.pairRow ? "Pair" : row.d.connected ? "Disconnect" : "Connect"
                onClicked: {
                    if (row.pairRow) {
                        row.pairRequested(row.d);
                    } else if (row.d.connected) {
                        row.d.disconnect();
                    } else {
                        row.d.connect();
                    }
                }
            }
        }

    }

    Column {
        id: content
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 8

        Item {
            width: parent.width
            height: 32

            BluetoothGlyph {
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                off: !root.powered
            }

            Column {
                x: 40
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: root.adapter ? "Bluetooth" : "No Bluetooth adapter"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    text: !root.adapter ? "Plug in a Bluetooth adapter to use devices." : root.powered ? (root.adapter.name || "Adapter") + " is on" : "Turned off"
                    color: "#6b7785"
                    font.pixelSize: 11
                }
            }

            CheckBox {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.adapter !== null
                text: "On"
                checked: root.powered
                onToggled: checked => root.adapter.enabled = checked
            }
        }

        SectionHeader {
            width: parent.width
            visible: root.powered
            text: "Devices"
        }

        Text {
            visible: root.powered && root.paired.length === 0
            text: "No devices paired yet."
            color: "#6b7785"
            font.pixelSize: 12
        }

        Column {
            width: parent.width
            visible: root.powered
            spacing: 1

            Repeater {
                model: root.paired

                DeviceRow {
                    width: content.width
                }
            }
        }

        Row {
            visible: root.powered
            spacing: 10

            PushButton {
                text: root.adapter?.discovering ? "Stop searching" : "Add a device"
                onClicked: root.adapter.discovering = !root.adapter.discovering
            }

            Text {
                id: searching
                anchors.verticalCenter: parent.verticalCenter
                visible: root.adapter?.discovering ?? false
                property int dots: 1
                text: "Searching" + ".".repeat(dots)
                color: "#6b7785"
                font.pixelSize: 11

                Timer {
                    running: searching.visible
                    repeat: true
                    interval: 450
                    onTriggered: searching.dots = searching.dots % 3 + 1
                }
            }
        }

        Column {
            width: parent.width
            visible: root.powered && (root.adapter?.discovering ?? false)
            spacing: 1

            SectionHeader {
                width: parent.width
                text: "Available"
            }

            Text {
                visible: root.found.length === 0
                text: "Make sure your device is turned on and discoverable."
                color: "#6b7785"
                font.pixelSize: 11
                topPadding: 4
            }

            Repeater {
                model: root.found

                DeviceRow {
                    width: content.width
                    pairRow: true
                    onPairRequested: device => {
                        root.pairing = device;
                        device.trusted = true;
                        device.pair();
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(0.6, 0.72, 0.85, 0.7)
        }

        LinkText {
            text: "Open Bluetooth settings"
            onClicked: Quickshell.execDetached(Constants.BLUETOOTH_SETTINGS_CMD)
        }
    }
}
