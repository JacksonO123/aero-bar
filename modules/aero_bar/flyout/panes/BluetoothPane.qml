import QtQuick
import Quickshell
import Quickshell.Bluetooth
import ".."
import "../../components"
import "../../../../utils/constants.js" as Constants

FlyoutPane {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var all: Bluetooth.devices.values
    readonly property var paired: all.filter(d => d.paired || d.bonded || d.connected).sort((a, b) => b.connected - a.connected)
    readonly property var found: all.filter(d => !(d.paired || d.bonded || d.connected) && d.deviceName !== "")
    readonly property real padding: 12

    // kept here, not on the row: the row moves to "Devices" once paired
    property var pairing: null

    function adapterStatus() {
        if (!adapter) {
            return "Plug in a Bluetooth adapter to use devices.";
        }
        if (adapter.state === BluetoothAdapterState.Blocked) {
            return "Blocked (rfkill unblock bluetooth)";
        }
        return powered ? (adapter.name || "Adapter") + " is on" : "Turned off";
    }

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

    onActiveChanged: {
        if (!root.active && discovering) {
            adapter.discovering = false;
        }
    }

    component DeviceRow: Item {
        id: row

        required property var modelData
        readonly property var d: modelData
        property bool pairRow: false

        signal pairRequested(var device)

        // a HoverHandler stays hovered over the row's link and button
        readonly property bool hovered: rowHover.hovered

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

        RowHighlight {
            id: rowHighlight
            anchors.fill: parent
            hot: row.hovered
        }

        HoverHandler {
            id: rowHover
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
                opacity: row.pairRow ? 0 : rowHighlight.opacity
                visible: opacity > 0
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
                    text: root.adapterStatus()
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
                model: ScriptModel {
                    values: root.paired
                }

                DeviceRow {
                    width: content.width
                }
            }
        }

        Row {
            visible: root.powered
            spacing: 10

            PushButton {
                text: root.discovering ? "Stop searching" : "Add a device"
                onClicked: root.adapter.discovering = !root.discovering
            }

            Text {
                id: searching
                anchors.verticalCenter: parent.verticalCenter
                visible: root.discovering
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
            visible: root.powered && root.discovering
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
                model: ScriptModel {
                    values: root.found
                }

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

        FlyoutRule {
            width: parent.width
        }

        LinkText {
            text: "Open Bluetooth settings"
            onClicked: Quickshell.execDetached(Constants.BLUETOOTH_SETTINGS_CMD)
        }
    }
}
