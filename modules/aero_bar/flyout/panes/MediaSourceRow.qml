import QtQuick
import "../../components"
import "../../../../services"

Item {
    id: row

    required property var player
    property bool active: false

    readonly property bool current: player === Media.player
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real length: Media.lengthOf(player)
    readonly property bool scrolling: active && rowHover.hovered

    readonly property real artSize: 64
    readonly property real textX: 12 + artSize + 12

    implicitHeight: 96

    // a HoverHandler, so the row stays hot over the controls too
    HoverHandler {
        id: rowHover
    }

    RowHighlight {
        anchors.fill: parent
        glass: true
        hot: rowHover.hovered
        selected: row.current
    }

    // before the controls, so they keep their own clicks
    MouseArea {
        anchors.fill: parent
        onClicked: Media.show(row.player)
    }

    AlbumArt {
        x: 12
        y: 12
        width: row.artSize
        height: row.artSize
        source: row.player?.trackArtUrl ?? ""
    }

    Column {
        x: row.textX
        y: 10
        width: controls.x - x - 10
        spacing: 1

        Row {
            id: identityLine
            width: parent.width
            spacing: 6

            Text {
                width: Math.min(implicitWidth, identityLine.width - statusDot.width - statusText.width - identityLine.spacing * 2)
                elide: Text.ElideRight
                text: row.player?.identity ?? ""
                color: "#6b7785"
                font.pixelSize: 10
            }

            Rectangle {
                id: statusDot
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: row.playing ? "#3fae2a" : "#a7b1bb"
                border.width: 1
                border.color: row.playing ? "#2a7d1b" : "#8a949e"
            }

            Text {
                id: statusText
                text: row.playing ? "Playing" : "Paused"
                color: row.playing ? "#2f7a22" : "#6b7785"
                font.pixelSize: 10
            }
        }

        ScrollingText {
            width: parent.width
            text: Media.titleOf(row.player)
            color: "#13263a"
            font.pixelSize: 13
            font.bold: true
            scrolling: row.scrolling
        }

        ScrollingText {
            width: parent.width
            visible: text !== ""
            text: row.player?.trackArtist ?? ""
            color: "#2f4559"
            font.pixelSize: 11
            scrolling: row.scrolling
        }
    }

    // disabled controls let clicks through, which would switch the taskbar's player
    MouseArea {
        anchors.fill: controls
    }

    TransportControls {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 10
        y: 10
        player: row.player
    }

    SeekBar {
        id: seekBar
        x: row.textX
        y: row.height - 22
        width: time.x - x - 10
        height: 8
        visible: row.length > 0
        position: row.player?.position ?? 0
        length: row.length
        seekable: Media.canSeekOf(row.player)
        playing: row.playing && row.active
        onSeek: seconds => Media.seek(seconds, row.player)
    }

    TextMetrics {
        id: timeSpace
        font: time.font
        text: row.length >= 3600 ? "0:00:00 / 0:00:00" : "00:00 / 00:00"
    }

    Text {
        id: time
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: seekBar.verticalCenter
        width: Math.ceil(timeSpace.advanceWidth)
        horizontalAlignment: Text.AlignRight
        visible: row.length > 0
        text: Media.formatTime(seekBar.shownPosition) + " / " + Media.formatTime(row.length)
        color: "#4a5a6a"
        font.pixelSize: 10
    }
}
