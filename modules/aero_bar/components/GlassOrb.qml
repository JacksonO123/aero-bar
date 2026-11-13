import QtQuick

// A glossy Aero orb (think the start orb / WMP play button). Children are drawn inside the orb,
// underneath the top gloss so they pick up the same reflection.
Item {
    id: root

    default property alias content: contentLayer.data

    property real size: 32
    property real hoverT: 0
    property real pressedT: 0

    property color lightColor: "#9eeeff"
    property color baseColor: "#1f7ad8"
    property color darkColor: "#06215a"
    property color glowColor: Qt.rgba(0.72, 0.96, 1.0, 0.9)

    implicitWidth: size
    implicitHeight: size

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Behavior on pressedT {
        NumberAnimation {
            duration: 90
            easing.type: Easing.OutQuad
        }
    }

    // soft contact shadow
    Rectangle {
        x: -1
        y: 0
        width: root.width + 2
        height: root.height + 2
        radius: width / 2
        color: Qt.rgba(0, 0, 0, 0.24)
    }

    Canvas {
        id: body
        anchors.fill: parent

        readonly property var colors: [root.lightColor, root.baseColor, root.darkColor]
        onColorsChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height, r = Math.min(w, h) / 2;
            if (r <= 0) {
                return;
            }

            // light pools at the bottom like the glow coming through a glass marble
            const g = ctx.createRadialGradient(w / 2, h * 0.96, 0, w / 2, h * 0.96, h * 1.02);
            g.addColorStop(0.0, root.lightColor);
            g.addColorStop(0.45, root.baseColor);
            g.addColorStop(1.0, root.darkColor);
            ctx.beginPath();
            ctx.arc(w / 2, h / 2, r, 0, Math.PI * 2);
            ctx.fillStyle = g;
            ctx.fill();
        }
    }

    Canvas {
        id: hotGlow
        anchors.fill: parent
        opacity: root.hoverT
        visible: opacity > 0

        readonly property color glowColor: root.glowColor
        onGlowColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height, r = Math.min(w, h) / 2;
            if (r <= 0) {
                return;
            }

            const g = ctx.createRadialGradient(w / 2, h * 0.92, 0, w / 2, h * 0.92, h * 0.8);
            g.addColorStop(0.0, glowColor);
            g.addColorStop(1.0, Qt.rgba(0.6, 0.9, 1.0, 0));
            ctx.beginPath();
            ctx.arc(w / 2, h / 2, r, 0, Math.PI * 2);
            ctx.fillStyle = g;
            ctx.fill();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(0, 0.02, 0.12, 0.3)
        opacity: root.pressedT
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.6)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.22)
    }

    Item {
        id: contentLayer
        anchors.fill: parent
    }

    Canvas {
        id: gloss
        anchors.fill: parent
        opacity: 1 - 0.35 * root.pressedT

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            if (w <= 0 || h <= 0) {
                return;
            }

            const g = ctx.createLinearGradient(0, h * 0.05, 0, h * 0.52);
            g.addColorStop(0.0, Qt.rgba(1, 1, 1, 0.82));
            g.addColorStop(1.0, Qt.rgba(1, 1, 1, 0.06));
            ctx.beginPath();
            ctx.ellipse(w * 0.17, h * 0.05, w * 0.66, h * 0.47);
            ctx.fillStyle = g;
            ctx.fill();
        }
    }
}
