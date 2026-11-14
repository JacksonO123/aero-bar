import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"
import "../../../services"
import "../../../utils/constants.js" as Constants

Scope {
    id: root

    property bool shown: false
    property var lastSink: null

    Component.onCompleted: lastSink = Audio.sink

    function poke() {
        // at startup or after a sink switch, the "changes" are the new sink's values
        if (Audio.sink !== lastSink) {
            lastSink = Audio.sink;
            settle.restart();
            return;
        }
        if (settle.running || !Audio.available || Audio.panesOpen > 0) {
            return;
        }
        root.shown = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio

        function onVolumeChanged() {
            root.poke();
        }

        function onMutedChanged() {
            root.poke();
        }

        // needed when the new sink has the same volume and mute
        function onSinkChanged() {
            root.poke();
        }

        function onPanesOpenChanged() {
            if (Audio.panesOpen > 0) {
                root.shown = false;
            }
        }
    }

    Timer {
        id: settle
        running: true
        interval: 1500
    }

    Timer {
        id: hideTimer
        interval: Constants.OSD_TIMEOUT
        onTriggered: root.shown = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            screen: modelData

            readonly property bool wanted: root.shown && Screens.focused === modelData.name

            visible: wanted || panel.opacity > 0.01
            anchors.bottom: true
            margins.bottom: 70
            exclusiveZone: 0
            implicitWidth: panel.width
            implicitHeight: panel.height + 10
            color: "transparent"
            mask: Region {}

            WlrLayershell.namespace: "aero-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Item {
                id: panel

                width: 300
                height: 64
                y: window.wanted ? 0 : 10
                opacity: window.wanted ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: window.wanted ? 120 : 400
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Aeroframe {
                    anchors.fill: parent
                    radius: 8
                    frameWidth: 0
                    topFrameWidth: 0
                    showContentFrame: false
                    sheenPeak: 0.5
                }

                GlossySpeaker {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 38
                    muted: Audio.muted
                }

                Row {
                    id: segments
                    x: 60
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: 20

                        Item {
                            required property int index
                            readonly property bool lit: Audio.volume > index * 0.05 + 0.001

                            width: 7
                            height: 16

                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                color: Qt.rgba(0, 0, 0, 0.4)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.12)
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                opacity: parent.lit ? 1 : 0
                                border.width: 1
                                border.color: Audio.muted ? Qt.rgba(0.2, 0.22, 0.25, 0.9) : Qt.rgba(0.02, 0.25, 0.5, 0.9)
                                gradient: SplitGradient {
                                    split: 0.48
                                    splitEnd: 0.52
                                    colors: [
                                        Audio.muted ? "#e3e7eb" : "#c8f4ff",
                                        Audio.muted ? "#b2bac2" : "#5cc6f5",
                                        Audio.muted ? "#8a949e" : "#1d8fe0",
                                        Audio.muted ? "#a3abb3" : "#3fb0f0"
                                    ]
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 90
                                    }
                                }
                            }
                        }
                    }
                }

                CaptionText {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100)
                    font.pixelSize: Audio.muted ? 13 : 20
                    font.bold: true
                }
            }
        }
    }
}
