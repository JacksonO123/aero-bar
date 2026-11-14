pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired)
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property var wiredUp: wiredDevices.find(d => d.connected) ?? null
    readonly property var wifiAll: wifiDevice ? wifiDevice.networks.values : []
    readonly property var wifiConnected: wifiAll.find(n => n.connected) ?? null
    // signal levels change constantly: only sort while a pane shows the list
    readonly property var wifiNetworks: panesOpen > 0 ? wifiAll.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []

    readonly property bool connected: wiredUp !== null || wifiConnected !== null
    readonly property string kind: (wiredUp || !wifiDevice) ? "wired" : "wifi"
    readonly property real strength: wifiConnected?.signalStrength ?? 0
    readonly property string name: wiredUp ? (wiredUp.network?.name || "Wired connection") : wifiConnected?.name ?? ""

    readonly property int connectivity: Networking.connectivity
    readonly property bool limited: connected && [NetworkConnectivity.Limited, NetworkConnectivity.Portal, NetworkConnectivity.None].includes(connectivity)
    readonly property string status: {
        if (!connected) {
            return "Not connected";
        }
        if (connectivity === NetworkConnectivity.Full) {
            return "Internet access";
        }
        if (connectivity === NetworkConnectivity.Portal) {
            return "Sign-in required";
        }
        if (connectivity === NetworkConnectivity.Limited || connectivity === NetworkConnectivity.None) {
            return "No Internet access";
        }
        return "Connected";
    }
    readonly property string badge: !connected ? "error" : limited ? "warning" : ""

    property int panesOpen: 0

    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.panesOpen > 0
        when: root.wifiDevice !== null
    }
}
