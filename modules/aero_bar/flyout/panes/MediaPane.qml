import QtQuick
import Quickshell
import ".."
import "../../components"
import "../../../../services"

// The media flyout. Hover the taskbar's media module: what's playing in the player it shows.
// Click it (the flyout is pinned): "Now Playing", every media source with its own controls.
FlyoutPane {
    id: root

    required property var flyoutEl

    // the list (pinned) or the hover view. Follows the flyout's pinning only while this pane
    // shows, a moment later, so it doesn't switch while fading out: when another module's pane
    // is pinned over it, or when the list closes.
    property bool showAll: false

    // the hover view is on screen (it's hidden while the list is pinned)
    readonly property bool hoverShown: active && !showAll

    readonly property var player: Media.player
    readonly property real position: player?.position ?? 0
    readonly property real length: Media.length
    // the playing players whose progress is on screen
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

    // mpris position isn't reactive; poll it only while this pane is on screen
    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: root.active && root.polled.length > 0
        onTriggered: root.polled.forEach(p => p.positionChanged())
    }

    // ---- the player the taskbar shows (hover) --------------------------------------------------

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

    // ---- every media source (click) ------------------------------------------------------------

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
            // about three and a half rows, then it scrolls
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

                    // built when the list first shows; a ScriptModel keeps each player's row as
                    // players come and go
                    Repeater {
                        model: ScriptModel {
                            values: root.showAll ? Media.players : []
                        }

                        MediaSourceRow {
                            required property var modelData
                            width: list.width
                            player: modelData
                            active: root.active && root.showAll
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
