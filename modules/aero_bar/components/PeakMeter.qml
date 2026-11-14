import QtQuick

Item {
    id: root

    property real level: 0
    property int segments: 30
    property real gap: 1.5
    property bool dimmed: false
    property real rangeDb: 54

    implicitWidth: 200
    implicitHeight: 6

    readonly property real target: level <= 0.00001 ? 0 : Math.max(0, Math.min(1, (20 * Math.log10(level) + rangeDb) / rangeDb))
    property real shown: 0
    property real hold: 0

    readonly property real segmentWidth: (width - (segments - 1) * gap) / segments
    readonly property int lit: Math.round(shown * segments)
    readonly property int held: Math.round(hold * segments)

    readonly property var palettes: ({
            unlit: ["#eef1f4", "#dde2e7", "#d3d9df", "#e6eaee"],
            dimmed: ["#d9dee3", "#b3bac1", "#9da5ad", "#b8bfc6"],
            hot: ["#ffe7a6", "#f7b73a", "#e0901a", "#f2ad33"],
            lit: ["#c9f7bd", "#5fd34e", "#2fb51f", "#4fcd40"]
        })

    onTargetChanged: {
        if (target > shown) {
            shown = target;
        }
        if (target >= hold) {
            hold = target;
            holdTimer.restart();
        }
    }

    Timer {
        id: holdTimer
        interval: 700
    }

    Timer {
        interval: 33
        repeat: true
        running: root.visible && (root.shown > 0 || root.hold > 0)
        onTriggered: {
            root.shown = Math.max(root.target, root.shown - 0.035);
            if (!holdTimer.running) {
                root.hold = Math.max(root.shown, root.hold - 0.02);
            }
        }
    }

    Row {
        spacing: root.gap

        Repeater {
            model: root.segments

            Rectangle {
                id: segment

                required property int index
                readonly property bool on: index < root.lit || index === root.held - 1
                readonly property bool hot: index >= root.segments * 0.86

                width: root.segmentWidth
                height: root.height
                radius: 1
                border.width: 1
                border.color: on ? (hot ? "#a8640f" : "#2d8a1f") : "#b9c3cd"

                gradient: SplitGradient {
                    colors: root.palettes[!segment.on ? "unlit" : root.dimmed ? "dimmed" : segment.hot ? "hot" : "lit"]
                }
            }
        }
    }
}
