pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

// What the network icon and flyout show, derived from Quickshell.Networking (NetworkManager).
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired)
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property var wiredUp: wiredDevices.find(d => d.connected) ?? null
    // connected first, then strongest
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []
    readonly property var wifiConnected: wifiNetworks.find(n => n.connected) ?? null

    readonly property bool connected: wiredUp !== null || wifiConnected !== null
    readonly property string kind: wiredUp || !wifiDevice ? "wired" : "wifi"
    readonly property real strength: wifiConnected?.signalStrength ?? 0
    readonly property string name: wiredUp ? (wiredUp.network?.name || "Wired connection") : wifiConnected?.name ?? ""

    readonly property int connectivity: Networking.connectivity
    readonly property bool limited: connected && (connectivity === NetworkConnectivity.Limited || connectivity === NetworkConnectivity.Portal || connectivity === NetworkConnectivity.None)
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
    // badge on the tray icon: "" | "warning" | "error"
    readonly property string badge: !connected ? "error" : limited ? "warning" : ""

    // network flyouts open: scan for Wi-Fi networks only while one is
    property int panesOpen: 0

    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.panesOpen > 0
        when: root.wifiDevice !== null
    }
}
