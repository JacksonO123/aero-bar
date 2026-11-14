import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".."
import "../../components"
import "../../../../services"
import "../../../../utils/constants.js" as Constants

FlyoutPane {
    id: root

    required property var flyoutEl
    property bool devicesOpen: false

    readonly property real padding: 12
    readonly property real innerWidth: width - padding * 2

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var streams: nodes.filter(n => n.audio && n.isStream && !n.isSink).slice(0, 6)

    width: 326
    height: content.height + padding * 2 - 2

    onActiveChanged: {
        if (!root.active) {
            devicesOpen = false;
        }
    }

    OpenCounter {
        target: Audio
        counter: "panesOpen"
        when: root.active
    }

    // Pipewire node properties are only valid while tracked
    PwObjectTracker {
        objects: root.active ? root.streams.concat(root.sinks) : []
    }

    PwNodePeakMonitor {
        id: peaks
        node: Audio.sink
        enabled: root.active && Audio.sink !== null
    }

    component HotTrack: Rectangle {
        property bool hot: false
        radius: 3
        border.width: 1
        border.color: "#b4d3f3"
        opacity: hot ? 1 : 0

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#fafdff"
            }
            GradientStop {
                position: 1
                color: "#e1f0fb"
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 110
            }
        }
    }

    component StreamRow: Item {
        id: row

        property var node: null
        readonly property bool dragging: slider.dragging

        readonly property var props: node?.properties ?? ({})
        readonly property string appName: props["application.name"] || node?.description || node?.name || "Unknown"
        readonly property string mediaName: props["media.name"] ?? ""
        readonly property bool muted: node?.audio?.muted ?? false

        height: 38

        HotTrack {
            anchors.fill: parent
            hot: rowHover.hovered
        }

        HoverHandler {
            id: rowHover
        }

        ImageIcon {
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            size: 24
            wmClass: row.props["application.process.binary"] ?? ""
            desktopIcon: row.props["application.icon-name"] ?? ""
            opacity: row.muted ? 0.5 : 1
        }

        Column {
            x: 38
            width: 92
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: row.appName
                elide: Text.ElideRight
                color: "#1e2f40"
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                width: parent.width
                visible: text !== "" && text !== row.appName
                text: row.mediaName
                elide: Text.ElideRight
                color: "#6b7785"
                font.pixelSize: 10
            }
        }

        AeroSlider {
            id: slider
            x: 134
            width: row.width - x - 34
            anchors.verticalCenter: parent.verticalCenter
            knobSize: 24
            trackHeight: 6
            value: row.node?.audio?.volume ?? 0
            muted: row.muted
            onMoved: value => Audio.setNodeVolume(row.node, value)
        }

        LightButton {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 24
            checked: row.muted
            onClicked: Audio.toggleNodeMute(row.node)

            SpeakerGlyph {
                anchors.centerIn: parent
                width: 15
                height: 13
                level: row.node?.audio?.volume ?? 0
                muted: row.muted
                color: "#1d3044"
                shadowColor: Qt.rgba(1, 1, 1, 0.85)
            }
        }
    }

    Column {
        id: content
        x: root.padding
        y: root.padding - 2
        width: root.innerWidth
        spacing: 6

        Item {
            id: deviceCard
            width: parent.width
            height: 50

            readonly property bool switchable: root.sinks.length > 1

            HotTrack {
                anchors.fill: parent
                hot: deviceCard.switchable && (deviceMouse.containsMouse || root.devicesOpen)
            }

            GlossySpeaker {
                x: 7
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 38
                muted: Audio.muted
            }

            Column {
                x: 48
                width: parent.width - x - 26
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: Audio.deviceName
                    elide: Text.ElideRight
                    color: "#1e2f40"
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: Audio.muted ? "Muted" : deviceCard.switchable ? "Default output · click to change" : "Default output device"
                    elide: Text.ElideRight
                    color: Audio.muted ? "#b3261e" : "#6b7785"
                    font.pixelSize: 10
                }
            }

            MediaGlyph {
                visible: deviceCard.switchable
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 9
                kind: "play"
                rotation: root.devicesOpen ? -90 : 90
                color: "#4d6377"
                shadow: false

                Behavior on rotation {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: deviceMouse
                anchors.fill: parent
                enabled: deviceCard.switchable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.devicesOpen = !root.devicesOpen
            }
        }

        Item {
            width: parent.width
            height: root.devicesOpen ? deviceList.implicitHeight : 0
            clip: true
            visible: height > 0

            Behavior on height {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                id: deviceList
                width: parent.width

                Repeater {
                    model: ScriptModel {
                        values: root.sinks
                    }

                    Item {
                        id: sinkRow
                        required property var modelData
                        readonly property bool current: modelData === Audio.sink

                        width: deviceList.width
                        height: 30

                        HotTrack {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            hot: sinkMouse.containsMouse
                        }

                        Loader {
                            x: 28
                            anchors.verticalCenter: parent.verticalCenter
                            active: sinkRow.current

                            sourceComponent: GlassOrb {
                                size: 12
                            }
                        }

                        Rectangle {
                            x: 28
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            radius: 6
                            visible: !sinkRow.current
                            color: "#f4f6f8"
                            border.color: "#8e9caa"
                        }

                        Text {
                            x: 48
                            width: parent.width - x - 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: Audio.nameOf(sinkRow.modelData)
                            elide: Text.ElideRight
                            color: "#1e2f40"
                            font.pixelSize: 11
                            font.bold: sinkRow.current
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Pipewire.preferredDefaultAudioSink = sinkRow.modelData;
                                root.devicesOpen = false;
                            }
                        }
                    }
                }
            }
        }

        Row {
            spacing: 10

            LightButton {
                width: 34
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                checked: Audio.muted
                onClicked: Audio.toggleMute()

                SpeakerGlyph {
                    anchors.centerIn: parent
                    width: 19
                    height: 17
                    level: Audio.volume
                    muted: Audio.muted
                    color: "#1d3044"
                    shadowColor: Qt.rgba(1, 1, 1, 0.85)
                }
            }

            Column {
                width: content.width - 44
                spacing: 1

                AeroSlider {
                    id: master
                    width: parent.width
                    knobSize: 32
                    value: Audio.volume
                    maximum: Audio.maxVolume
                    muted: Audio.muted
                    onMoved: value => Audio.setVolume(value)

                    OpenCounter {
                        target: root.flyoutEl
                        counter: "holdCount"
                        when: master.dragging
                    }
                }

                PeakMeter {
                    x: master.knobSize / 2 - 2
                    width: master.width - master.knobSize + 4
                    height: 5
                    level: peaks.peak * (Audio.muted ? 0 : Math.min(1, Audio.volume))
                    dimmed: Audio.muted
                }
            }
        }

        SectionHeader {
            width: parent.width
            visible: root.streams.length > 0
            text: "Applications"
        }

        Repeater {
            model: ScriptModel {
                values: root.streams
            }

            StreamRow {
                id: streamRow
                required property var modelData
                width: content.width
                node: modelData

                OpenCounter {
                    target: root.flyoutEl
                    counter: "holdCount"
                    when: streamRow.dragging
                }
            }
        }

        Item {
            width: parent.width
            height: 16

            LinkText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Mixer"
                restColor: "#0066cc"
                font.pixelSize: 11
                onClicked: Quickshell.execDetached(Constants.VOLUME_MIXER_CMD)
            }
        }
    }
}
