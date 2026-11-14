import QtQuick
import "../../../services"

Item {
    id: root

    required property var player

    readonly property bool playing: player?.isPlaying ?? false
    readonly property bool canPrevious: player?.canGoPrevious ?? false
    readonly property bool canNext: player?.canGoNext ?? false
    readonly property bool canToggle: player?.canTogglePlaying ?? false

    readonly property real orbSize: 40
    readonly property real capsuleHeight: 26

    implicitWidth: 140
    implicitHeight: orbSize + 4

    component CapsuleSegment: Item {
        id: segment

        property string glyph: "prev"
        property bool active: true
        signal activated

        opacity: active ? 1 : 0.4

        HoverPress {
            id: hp
            pressed: segmentMouse.pressed
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: height / 2
            opacity: segmentMouse.containsMouse ? 1 : 0

            gradient: SplitGradient {
                colors: {
                    const top = hp.shade("#eef8ff", "#eef8ff", "#cfe9fa");
                    const aboveSplit = hp.shade("#cbe9fc", "#cbe9fc", "#9fd2f2");
                    const belowSplit = hp.shade("#a9dcfa", "#a9dcfa", "#79bfea");
                    const bottom = hp.shade("#d4eefd", "#d4eefd", "#a6d6f3");
                    return [top, aboveSplit, belowSplit, bottom];
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }
        }

        MediaGlyph {
            anchors.verticalCenter: parent.verticalCenter
            x: segment.glyph === "prev" ? 12 : parent.width - width - 12
            width: 13
            height: 11
            kind: segment.glyph
            color: "#22364a"
            shadowColor: Qt.rgba(1, 1, 1, 0.85)
        }

        MouseArea {
            id: segmentMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: segment.active
            cursorShape: Qt.PointingHandCursor
            onClicked: segment.activated()
        }
    }

    Rectangle {
        id: capsule
        anchors.centerIn: parent
        width: parent.width
        height: root.capsuleHeight
        radius: height / 2
        border.width: 1
        border.color: "#7b8794"

        gradient: SplitGradient {
            split: 0.49
            splitEnd: 0.5
            colors: ["#fdfdfd", "#e6e9ec", "#d1d6db", "#eceff2"]
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.8)
        }
    }

    CapsuleSegment {
        x: capsule.x
        y: capsule.y
        width: capsule.width / 2
        height: capsule.height
        glyph: "prev"
        active: root.canPrevious
        onActivated: Media.previous(root.player)
    }

    CapsuleSegment {
        x: capsule.x + capsule.width / 2
        y: capsule.y
        width: capsule.width / 2
        height: capsule.height
        glyph: "next"
        active: root.canNext
        onActivated: Media.next(root.player)
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.orbSize + 6
        height: width
        radius: width / 2
        border.width: 1
        border.color: "#8995a1"

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#ffffff"
            }
            GradientStop {
                position: 1.0
                color: "#c4ccd4"
            }
        }
    }

    GlassOrb {
        id: orb
        anchors.centerIn: parent
        size: root.orbSize
        hoverT: orbMouse.containsMouse ? 1 : 0
        pressedT: orbMouse.pressed ? 1 : 0
        opacity: root.canToggle ? 1 : 0.6

        MediaGlyph {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.playing ? 0 : 1.5
            width: 15
            height: 16
            kind: root.playing ? "pause" : "play"
            color: "white"
            shadowColor: Qt.rgba(0, 0.05, 0.2, 0.6)
        }

        MouseArea {
            id: orbMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.canToggle
            cursorShape: Qt.PointingHandCursor
            onClicked: Media.togglePlaying(root.player)

            containmentMask: QtObject {
                function contains(point: point): bool {
                    const r = orb.width / 2;
                    const dx = point.x - r;
                    const dy = point.y - r;
                    return dx * dx + dy * dy <= r * r;
                }
            }
        }
    }
}
