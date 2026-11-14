import QtQuick

// Windows 7 style green progress bar (with the travelling highlight while playing). Seekable.
Item {
    id: root

    property real position: 0
    property real length: 0
    property bool seekable: false
    property bool playing: false

    signal seek(real seconds)

    property bool scrubbing: false
    property real scrubPosition: 0

    readonly property real shownPosition: scrubbing ? scrubPosition : position
    readonly property real ratio: length > 0 ? Math.max(0, Math.min(1, shownPosition / length)) : 0

    implicitWidth: 200
    implicitHeight: 10

    function positionAt(x) {
        return Math.max(0, Math.min(length, x / Math.max(1, width) * length));
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 3
        border.width: 1
        // turns blue under the pointer (and while scrubbing), like a text box
        border.color: seekMouse.enabled && (seekMouse.containsMouse || root.scrubbing) ? "#5794bf" : "#8b97a3"

        Behavior on border.color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#c6cdd4"
            }
            GradientStop {
                position: 1.0
                color: "#f1f3f5"
            }
        }
    }

    Item {
        id: fill
        x: 1
        y: 1
        height: parent.height - 2
        width: Math.max(0, (parent.width - 2) * root.ratio)
        clip: true

        // position only updates twice a second, so ease between updates
        Behavior on width {
            enabled: !root.scrubbing
            NumberAnimation {
                duration: 480
            }
        }

        Rectangle {
            width: track.width - 2
            height: parent.height
            radius: 2

            gradient: SplitGradient {
                split: 0.45
                splitEnd: 0.46
                colors: ["#c9f5c0", "#6fd85d", "#30b420", "#56d046"]
            }
        }

        Rectangle {
            id: sweep
            width: 80
            height: parent.height
            visible: root.playing

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.rgba(1, 1, 1, 0.55)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }

            NumberAnimation on x {
                from: -sweep.width
                to: root.width + 10
                duration: 2400
                loops: Animation.Infinite
                running: root.playing && fill.width > 0
            }
        }
    }

    MouseArea {
        id: seekMouse
        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        hoverEnabled: true
        enabled: root.seekable && root.length > 0
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        preventStealing: true

        onPressed: mouse => {
            root.scrubPosition = root.positionAt(mouse.x);
            root.scrubbing = true;
        }
        onPositionChanged: mouse => {
            if (root.scrubbing) {
                root.scrubPosition = root.positionAt(mouse.x);
            }
        }
        onReleased: {
            root.seek(root.scrubPosition);
            root.scrubbing = false;
        }
        onCanceled: root.scrubbing = false
    }
}
