import QtQuick
import Quickshell
import Quickshell.Networking
import ".."
import "../../components"
import "../../../../services"
import "../../../../utils/constants.js" as Constants

FlyoutPane {
    id: root

    wantsKeyboard: true

    property var selected: null
    property bool askKey: false
    // kept here, not in the row: a rescan can recreate the row
    property string key: ""
    property string error: ""
    // apart from selected: its failure can arrive after it was deselected
    property var attempt: null

    readonly property real padding: 12
    readonly property bool wifiOn: NetState.wifiDevice !== null && Networking.wifiEnabled && Networking.wifiHardwareEnabled

    width: 330
    height: content.height + padding * 2

    onActiveChanged: {
        if (!root.active) {
            select(null);
        }
    }

    OpenCounter {
        target: NetState
        counter: "panesOpen"
        when: root.active
    }

    function select(n) {
        // askKey first: shown in the newly selected row, the key box would take focus
        askKey = false;
        key = "";
        error = "";
        selected = n;
    }

    // NetworkManager drops an invalid WPA key without reporting a failure
    function submitKey() {
        if (!/^(.{8,63}|[0-9a-fA-F]{64})$/.test(key)) {
            return;
        }
        const psk = key;
        key = "";
        askKey = false;
        attempt = selected;
        selected?.connectWithPsk(psk);
    }

    function needsKey(n) {
        return !n.known && n.security !== WifiSecurityType.Open;
    }

    function keyAllowed(n) {
        return n.security === WifiSecurityType.WpaPsk || n.security === WifiSecurityType.Wpa2Psk || n.security === WifiSecurityType.Sae;
    }

    function connectTo(n) {
        error = "";
        if (needsKey(n)) {
            if (keyAllowed(n)) {
                askKey = true;
            } else {
                error = "This network needs a sign-in; use Network settings.";
            }
        } else {
            attempt = n;
            n.connect();
        }
    }

    function speedText(mbps) {
        return mbps >= 1000 ? (mbps / 1000) + " Gbps" : mbps + " Mbps";
    }

    function wiredStatus(device) {
        if (!device.hasLink) {
            return "Network cable unplugged";
        }
        const state = device.connected ? "Connected" : "Cable plugged in, not in use";
        return device.linkSpeed > 0 ? state + " · " + speedText(device.linkSpeed) : state;
    }

    function wifiStatus(n) {
        if (n.stateChanging) {
            return n.state === ConnectionState.Disconnecting ? "Disconnecting…" : "Connecting…";
        }
        if (n.connected) {
            return "Connected";
        }
        if (n.known) {
            return "Saved network";
        }
        return n.security === WifiSecurityType.Open ? "Open network" : "Secured network";
    }

    Connections {
        target: root.attempt
        ignoreUnknownSignals: true

        // later drops report the old failure reason again
        function onConnectedChanged() {
            if (root.attempt?.connected) {
                root.attempt = null;
            }
        }

        function onConnectionFailed(reason) {
            root.select(root.attempt);
            if (reason === ConnectionFailReason.NoSecrets) {
                root.askKey = root.keyAllowed(root.selected);
                root.error = "Enter the network security key";
            } else {
                root.error = "Couldn't connect to this network.";
            }
        }
    }

    Column {
        id: content
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 8

        Text {
            text: NetState.connected ? "Currently connected to:" : "Not connected"
            color: "#6b7785"
            font.pixelSize: 11
        }

        Row {
            spacing: 10

            NetworkGlyph {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 30
                onGlass: false
                kind: NetState.kind
                strength: NetState.strength
                badge: NetState.badge
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: NetState.connected ? NetState.name : "No connections"
                    color: "#1a1a1a"
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    text: NetState.connected ? NetState.status : (root.wifiOn ? "Connections are available" : "Plug in a cable or turn on Wi-Fi")
                    color: NetState.limited ? "#9a6a00" : "#6b7785"
                    font.pixelSize: 11
                }
            }
        }

        SectionHeader {
            width: parent.width
            visible: NetState.wiredDevices.length > 0
            text: "Local Area Connection"
        }

        Repeater {
            model: NetState.wiredDevices

            Item {
                id: wired
                required property var modelData
                readonly property var device: modelData

                width: content.width
                height: 34

                NetworkGlyph {
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 18
                    onGlass: false
                    kind: "wired"
                    badge: wired.device.hasLink ? "" : "error"
                }

                Column {
                    x: 34
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: wired.device.network?.name || wired.device.name
                        color: "#1a1a1a"
                        font.pixelSize: 12
                    }
                    Text {
                        text: root.wiredStatus(wired.device)
                        color: "#6b7785"
                        font.pixelSize: 11
                    }
                }

                LinkText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: wired.device.hasLink
                    text: wired.device.connected ? "Disconnect" : "Connect"
                    onClicked: wired.device.connected ? wired.device.disconnect() : wired.device.network?.connect()
                }
            }
        }

        Item {
            width: parent.width
            height: 18
            visible: NetState.wifiDevice !== null

            SectionHeader {
                width: parent.width - wifiToggle.width - 10
                text: "Wireless Network Connection"
            }

            CheckBox {
                id: wifiToggle
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "On"
                checked: Networking.wifiEnabled
                onToggled: checked => Networking.wifiEnabled = checked
            }
        }

        Text {
            visible: NetState.wifiDevice !== null && !root.wifiOn
            text: Networking.wifiHardwareEnabled ? "Wi-Fi is turned off." : "Wi-Fi is switched off on this computer."
            color: "#6b7785"
            font.pixelSize: 12
        }

        Text {
            visible: root.wifiOn && NetState.wifiNetworks.length === 0
            text: "Looking for networks…"
            color: "#6b7785"
            font.pixelSize: 12
        }

        Flickable {
            id: wifiList
            width: parent.width
            height: Math.min(wifiColumn.height, 270)
            visible: root.wifiOn && NetState.wifiNetworks.length > 0
            contentHeight: wifiColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: wifiColumn
                width: wifiList.width
                spacing: 1

                Repeater {
                    // a ScriptModel keeps rows when scans re-sort the list
                    model: ScriptModel {
                        values: NetState.wifiNetworks
                    }

                    Item {
                        id: net
                        required property var modelData
                        readonly property var n: modelData
                        readonly property bool isSelected: root.selected === n

                        width: wifiColumn.width
                        height: isSelected ? 30 + details.height + 8 : 30

                        RowHighlight {
                            anchors.fill: parent
                            hot: netMouse.containsMouse
                            selected: net.isSelected
                        }

                        MouseArea {
                            id: netMouse
                            width: parent.width
                            height: 30
                            hoverEnabled: true
                            onClicked: root.select(net.isSelected ? null : net.n)
                        }

                        Text {
                            x: 8
                            y: 7
                            width: parent.width - 80
                            text: net.n.name
                            color: "#1a1a1a"
                            font.pixelSize: 12
                            font.bold: net.n.connected
                            elide: Text.ElideRight
                        }

                        Canvas {
                            x: parent.width - 52
                            y: 8
                            width: 10
                            height: 13
                            visible: net.n.security !== WifiSecurityType.Open
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = "#6b7785";
                                ctx.lineWidth = 1.4;
                                ctx.beginPath();
                                ctx.arc(5, 5, 3, Math.PI, 0);
                                ctx.lineTo(8, 7);
                                ctx.moveTo(2, 7);
                                ctx.lineTo(2, 5);
                                ctx.stroke();
                                const g = ctx.createLinearGradient(0, 6, 0, 13);
                                g.addColorStop(0, "#ffe27a");
                                g.addColorStop(1, "#c88a12");
                                ctx.fillStyle = g;
                                ctx.fillRect(0.5, 6.5, 9, 6);
                            }
                        }

                        NetworkGlyph {
                            x: parent.width - 32
                            y: 6
                            width: 22
                            height: 18
                            onGlass: false
                            kind: "wifi"
                            strength: net.n.signalStrength
                        }

                        Loader {
                            id: details
                            x: 8
                            y: 32
                            width: parent.width - 16
                            active: net.isSelected

                            sourceComponent: Column {
                                spacing: 6

                                Text {
                                    text: root.wifiStatus(net.n)
                                    color: "#6b7785"
                                    font.pixelSize: 11
                                }

                                Row {
                                    visible: root.askKey
                                    spacing: 6

                                    TextField {
                                        width: 180
                                        placeholder: "Security key"
                                        echoMode: TextInput.Password
                                        autoFocus: true
                                        text: root.key
                                        onTextChanged: root.key = text
                                        // a hidden box can keep the focus: ignore its Enter
                                        onAccepted: {
                                            if (root.askKey) {
                                                root.submitKey();
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: root.error !== ""
                                    text: root.error
                                    color: "#b3261e"
                                    font.pixelSize: 11
                                }

                                Item {
                                    width: parent.width
                                    height: 24

                                    LinkText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: net.n.known
                                        text: "Forget"
                                        onClicked: {
                                            net.n.forget();
                                            root.select(null);
                                        }
                                    }

                                    PushButton {
                                        anchors.right: parent.right
                                        text: net.n.connected ? "Disconnect" : "Connect"
                                        isDefault: !net.n.connected
                                        enabled: !net.n.stateChanging
                                        onClicked: {
                                            if (net.n.connected) {
                                                root.attempt = null;
                                                net.n.disconnect();
                                            } else if (root.askKey) {
                                                root.submitKey();
                                            } else {
                                                root.connectTo(net.n);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        FlyoutRule {
            width: parent.width
        }

        LinkText {
            text: "Open Network and Sharing Center"
            onClicked: Quickshell.execDetached(Constants.NETWORK_SETTINGS_CMD)
        }
    }
}
