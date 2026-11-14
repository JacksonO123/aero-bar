import QtQuick
import "../../components"
import "../../../../services"

// One media source in the "Now Playing" list: its album art, what it's playing, its own
// controls and progress. The one the taskbar shows is highlighted; clicking the row makes it
// that one.
Item {
    id: row

    required property var player
    // the pane is on screen: titles scroll, progress moves
    property bool active: false

    readonly property bool current: player === Media.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: Media.lengthOf(player)

    readonly property real artSize: 64
    readonly property real textX: 12 + artSize + 12

    implicitHeight: 96

    // on the row itself, so it stays hot over the controls too
    HoverHandler {
        id: rowHover
    }

    RowHighlight {
        anchors.fill: parent
        glass: true
        hot: rowHover.hovered
        selected: row.current
    }

    // under the controls, so they keep their own clicks
    MouseArea {
        anchors.fill: parent
        onClicked: Media.show(row.player)
    }

    AlbumArt {
        x: 12
        y: 12
        width: row.artSize
        height: row.artSize
        radius: 3
        source: row.player?.trackArtUrl ?? ""
    }

    Column {
        x: row.textX
        y: 10
        width: controls.x - x - 10
        spacing: 1

        // the app, and whether it's playing
        Row {
            spacing: 6

            Text {
                text: row.player?.identity ?? ""
                color: "#6b7785"
                font.pixelSize: 10
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: row.playing ? "#3fae2a" : "#a7b1bb"
                border.width: 1
                border.color: row.playing ? "#2a7d1b" : "#8a949e"
            }

            Text {
                text: row.playing ? "Playing" : "Paused"
                color: row.playing ? "#2f7a22" : "#6b7785"
                font.pixelSize: 10
            }
        }

        ScrollingText {
            width: parent.width
            text: row.player?.trackTitle || "Unknown Title"
            color: "#13263a"
            font.pixelSize: 13
            font.bold: true
            scrolling: row.active && rowHover.hovered
        }

        ScrollingText {
            width: parent.width
            visible: text !== ""
            text: row.player?.trackArtist ?? ""
            color: "#2f4559"
            font.pixelSize: 11
            scrolling: row.active && rowHover.hovered
        }
    }

    TransportControls {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 10
        playing: row.playing
        canPrevious: row.player?.canGoPrevious ?? false
        canNext: row.player?.canGoNext ?? false
        canToggle: row.player?.canTogglePlaying ?? false
        onPrevious: Media.previous(row.player)
        onNext: Media.next(row.player)
        onToggle: Media.togglePlaying(row.player)
    }

    // progress, under the title and the controls
    SeekBar {
        id: seekBar
        x: row.textX
        y: row.height - 22
        width: time.x - x - 10
        height: 8
        visible: row.length > 0
        position: row.player?.position ?? 0
        length: row.length
        seekable: (row.player?.canSeek ?? false) && (row.player?.positionSupported ?? false)
        playing: row.playing && row.active
        onSeek: seconds => Media.seek(seconds, row.player)
    }

    Text {
        id: time
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: seekBar.verticalCenter
        visible: row.length > 0
        text: Media.formatTime(seekBar.shownPosition) + " / " + Media.formatTime(row.length)
        color: "#4a5a6a"
        font.pixelSize: 10
    }
}
