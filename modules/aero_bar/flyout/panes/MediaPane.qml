import QtQuick
import "../../components"
import "../../../../services"

Item {
    id: root

    property bool shown: false

    readonly property var player: Media.player
    readonly property real position: player?.position ?? 0
    readonly property real length: Media.length

    readonly property real artSize: 92
    readonly property real padding: 10

    width: 340
    height: content.height + padding * 2

    // mpris position isn't reactive; poll it only while this pane is on screen
    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: root.shown && Media.isPlaying
        onTriggered: root.player?.positionChanged()
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`;
    }

    Column {
        id: content
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 6

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
                id: details
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
                    scrolling: root.shown
                }

                ScrollingText {
                    width: parent.width
                    text: Media.artist
                    color: "#2f4559"
                    font.pixelSize: 12
                    scrolling: root.shown
                }

                ScrollingText {
                    width: parent.width
                    visible: Media.album !== ""
                    text: Media.album
                    color: "#6b7785"
                    font.pixelSize: 11
                    scrolling: root.shown
                }

                Item {
                    width: 1
                    height: 4
                }

                TransportControls {
                    anchors.horizontalCenter: parent.horizontalCenter
                    playing: Media.isPlaying
                    canPrevious: Media.canPrevious
                    canNext: Media.canNext
                    canToggle: Media.canToggle
                    onPrevious: Media.previous()
                    onNext: Media.next()
                    onToggle: Media.togglePlaying()
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
                text: root.formatTime(seekBar.shownPosition)
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
                playing: Media.isPlaying && root.shown
                onSeek: seconds => Media.seek(seconds)
            }

            Text {
                width: 36
                anchors.verticalCenter: parent.verticalCenter
                text: root.formatTime(root.length)
                color: "#4a5a6a"
                font.pixelSize: 10
            }
        }
    }
}
