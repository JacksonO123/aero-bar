import QtQuick

Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property bool scrolling: false

    // via TextMetrics: an elided Text can report a stale (elided) implicitWidth
    readonly property real naturalWidth: Math.ceil(metrics.advanceWidth)
    readonly property real overflow: Math.max(0, naturalWidth - width)

    implicitWidth: naturalWidth
    implicitHeight: label.implicitHeight
    clip: true

    TextMetrics {
        id: metrics
        font: label.font
        text: label.text
    }

    Text {
        id: label
        width: marquee.running ? root.naturalWidth : root.width
        elide: marquee.running ? Text.ElideNone : Text.ElideRight
        maximumLineCount: 1
    }

    SequentialAnimation {
        id: marquee
        running: root.scrolling && root.overflow > 0
        loops: Animation.Infinite
        onRunningChanged: {
            if (!running) {
                label.x = 0;
            }
        }

        PauseAnimation {
            duration: 900
        }
        NumberAnimation {
            target: label
            property: "x"
            from: 0
            to: -root.overflow
            // 30 px/s
            duration: Math.max(400, root.overflow / 30 * 1000)
            easing.type: Easing.InOutSine
        }
        PauseAnimation {
            duration: 1200
        }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: 380
            easing.type: Easing.OutCubic
        }
    }
}
