import QtQuick
import "../flyout"
import "../../../services"

Win7Frame {
    id: root

    required property Flyout flyoutEl
    property real maxTextWidth: 170

    readonly property bool active: Media.hasPlayer

    visible: active
    implicitWidth: active ? content.implicitWidth + 14 : 0
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 3
    anchors.bottomMargin: 3
    frameOpacity: hoverT

    onHoveredChanged: hovered ? flyoutEl.hover(root) : flyoutEl.unhover()

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            flyoutEl.toggle(root);
        } else if (mouse.button === Qt.MiddleButton) {
            Media.togglePlaying();
        } else if (mouse.button === Qt.RightButton) {
            Media.raise();
        }
    }

    Win7Hover {
        radius: root.radius
        opacity: root.hoverT
        pressedT: root.pressedT
    }

    Row {
        id: content
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        AlbumArt {
            id: art
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            source: Media.artUrl

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 2
                color: Qt.rgba(0, 0, 0, 0.38)
                opacity: Media.isPlaying ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                    }
                }

                MediaGlyph {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    width: 10
                    height: 11
                    kind: "play"
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            ScrollingText {
                width: Math.min(implicitWidth, root.maxTextWidth)
                text: Media.title
                color: "white"
                font.pointSize: 10
                scrolling: root.hoverT > 0.5
            }

            ScrollingText {
                visible: Media.artist !== ""
                width: Math.min(implicitWidth, root.maxTextWidth)
                text: Media.artist
                color: Qt.rgba(1, 1, 1, 0.7)
                font.pointSize: 8.5
                scrolling: root.hoverT > 0.5
            }
        }
    }
}
