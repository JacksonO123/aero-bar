import QtQuick
import Quickshell
import ".."
import "../../components"
import "../../../../services"

FlyoutPane {
    id: root

    required property var flyoutEl

    // Flyout.toggle sets pinned before show(), so latch showAll a moment later
    property bool showAll: false

    readonly property bool hoverShown: active && !showAll

    readonly property var player: Media.player
    readonly property real position: player?.position ?? 0
    readonly property real length: Media.length
    readonly property var polled: showAll ? Media.playing : (Media.isPlaying ? [player] : [])

    readonly property real artSize: 92
    readonly property real padding: 10

    width: showAll ? 460 : 340
    height: (showAll ? sources.height : content.height) + padding * 2

    Binding {
        target: root
        property: "showAll"
        value: root.flyoutEl.pinned
        when: root.active
        delayed: true
        restoreMode: Binding.RestoreNone
    }

    // MPRIS position isn't reactive: poll it
    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: root.active && root.polled.length > 0
        onTriggered: root.polled.forEach(p => p.positionChanged())
    }

    Column {
        id: content
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 6
        visible: !root.showAll

        Row {
            spacing: 12

            Column {
                AlbumArt {
                    id: art
                    width: root.artSize
                    height: root.artSize
                    radius: 4
                    source: Media.artUrl
                }

                Reflection {
                    target: art
                    fraction: 0.26
                    strength: 0.32
                }
            }

            Column {
                width: content.width - root.artSize - 12
                spacing: 1

                Item {
                    width: parent.width
                    height: 15

                    Text {
                        width: parent.width - (switchLink.visible ? switchLink.width + 8 : 0)
                        text: Media.identity
                        color: "#6b7785"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    LinkText {
                        id: switchLink
                        anchors.right: parent.right
                        visible: Media.players.length > 1
                        text: "Switch player"
                        restColor: "#0066cc"
                        font.pixelSize: 10
                        onClicked: Media.cycle()
                    }
                }

                ScrollingText {
                    width: parent.width
                    text: Media.title
                    color: "#13263a"
                    font.pixelSize: 14
                    font.bold: true
                    scrolling: root.hoverShown
                }

                ScrollingText {
                    width: parent.width
                    text: Media.artist
                    color: "#2f4559"
                    font.pixelSize: 12
                    scrolling: root.hoverShown
                }

                ScrollingText {
                    width: parent.width
                    visible: Media.album !== ""
                    text: Media.album
                    color: "#6b7785"
                    font.pixelSize: 11
                    scrolling: root.hoverShown
                }

                Item {
                    width: 1
                    height: 4
                }

                TransportControls {
                    anchors.horizontalCenter: parent.horizontalCenter
                    player: root.player
                }
            }
        }

        Row {
            visible: root.length > 0
            spacing: 8

            Text {
                width: 36
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: Media.formatTime(seekBar.shownPosition)
                color: "#4a5a6a"
                font.pixelSize: 10
            }

            SeekBar {
                id: seekBar
                width: content.width - 2 * 36 - 16
                height: 10
                anchors.verticalCenter: parent.verticalCenter
                position: root.position
                length: root.length
                seekable: Media.canSeek
                playing: Media.isPlaying && root.hoverShown
                onSeek: seconds => Media.seek(seconds)
            }

            Text {
                width: 36
                anchors.verticalCenter: parent.verticalCenter
                text: Media.formatTime(root.length)
                color: "#4a5a6a"
                font.pixelSize: 10
            }
        }
    }

    Column {
        id: sources
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 8
        visible: root.showAll

        Item {
            width: parent.width
            height: heading.height

            Text {
                id: heading
                text: "Now Playing"
                color: "#1e3c78"
                font.pixelSize: 15
            }

            Text {
                anchors.right: parent.right
                anchors.baseline: heading.baseline
                text: Media.players.length === 1 ? "1 source" : Media.players.length + " sources"
                color: "#6b7785"
                font.pixelSize: 11
            }
        }

        FlyoutRule {
            width: parent.width
        }

        Item {
            width: parent.width
            // three and a half rows, then it scrolls
            height: Math.min(list.height, 350)

            Flickable {
                id: scroller
                anchors.fill: parent
                contentHeight: list.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: list
                    width: scroller.width
                    spacing: 4

                    // a ScriptModel keeps each player's row as players come and go
                    Repeater {
                        model: ScriptModel {
                            values: root.showAll ? Media.players : []
                        }

                        MediaSourceRow {
                            required property var modelData
                            width: list.width
                            player: modelData
                            active: root.active
                        }
                    }
                }
            }

            ScrollThumb {
                anchors.right: parent.right
                flickable: scroller
            }
        }
    }
}
