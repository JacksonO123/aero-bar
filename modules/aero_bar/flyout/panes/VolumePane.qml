import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../components"
import "../../../../services"
import "../../../../utils/constants.js" as Constants

// Windows 7 volume flyout, Aero'd up:
//  - output device card (glossy speaker), click to pick another output
//  - master slider with the orb knob and a live peak meter underneath
//  - per-application volume for everything currently playing
Item {
    id: root

    property bool shown: false
    // the flyout is held open while a slider is being dragged
    property var flyoutEl: null
    property bool devicesOpen: false

    readonly property real padding: 12
    readonly property real innerWidth: width - padding * 2

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var streams: nodes.filter(n => n.audio && n.isStream && !n.isSink).slice(0, 6)

    width: 326
    height: content.height + padding * 2 - 2

    onShownChanged: {
        if (!shown) {
            devicesOpen = false;
        }
    }

    // keeps the volume pop-up away while this is open
    OpenCounter {
        target: Audio
        counter: "flyoutsOpen"
        when: root.shown
    }

    // stream volumes/properties are only valid while bound; only bother while visible
    PwObjectTracker {
        objects: root.shown ? root.streams.concat(root.sinks) : []
    }

    PwNodePeakMonitor {
        id: peaks
        node: Audio.sink
        enabled: root.shown && Audio.sink !== null
    }

    // light-blue Win7 hot-track highlight
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
            id: appIcon
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
            onMoved: value => {
                if (row.node?.audio) {
                    if (row.node.audio.muted && value > 0) {
                        row.node.audio.muted = false;
                    }
                    row.node.audio.volume = value;
                }
            }
        }

        LightButton {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 24
            checked: row.muted
            onClicked: {
                if (row.node?.audio) {
                    row.node.audio.muted = !row.node.audio.muted;
                }
            }

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

        // ---- output device
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

        // ---- device picker (slides open under the card)
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
                    model: root.sinks

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

                        // radio orb
                        GlassOrb {
                            x: 28
                            anchors.verticalCenter: parent.verticalCenter
                            size: 12
                            visible: sinkRow.current
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
                            text: sinkRow.modelData.description || sinkRow.modelData.nickname || sinkRow.modelData.name
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

        // ---- master volume
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
                id: masterColumn
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

                    // keep the flyout open while dragging, even off its edge
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

        // ---- applications
        SectionHeader {
            width: parent.width
            visible: root.streams.length > 0
            text: "Applications"
        }

        Repeater {
            model: root.streams

            StreamRow {
                id: streamRow
                required property var modelData
                width: content.width
                node: modelData

                // (also gives the hold back if the row is rebuilt mid-drag)
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
