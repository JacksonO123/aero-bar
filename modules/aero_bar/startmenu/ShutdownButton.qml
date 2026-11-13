import QtQuick
import "../components"

// The Windows 7 "Shut down ▸" split button: one dark glass shell split into a label half and an
// arrow half. Each half glows pale blue from below on hover and darkens when pressed; the arrow
// half stays pressed while its menu is open.
Item {
    id: root

    property string label: "Shut down"
    property bool menuOpen: false
    property real arrowWidth: 20
    property real radius: 3

    readonly property real mainWidth: width - arrowWidth

    signal clicked
    signal arrowClicked

    implicitWidth: labelText.implicitWidth + 30 + arrowWidth
    implicitHeight: 23

    // one half's hover / pressed glow, drawn in the full button shape and clipped to the half
    component SegmentGlow: Canvas {
        id: glow

        property real fullWidth: 0
        property real offsetX: 0
        property real radius: 3
        property bool pressed: false
        property bool lit: false

        opacity: lit ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuad
            }
        }

        onPressedChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onFullWidthChanged: requestPaint()
        onOffsetXChanged: requestPaint()
        onRadiusChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            if (w <= 0 || h <= 0) {
                return;
            }

            ctx.save();
            ctx.beginPath();
            ctx.roundedRect(1 - offsetX, 1, fullWidth - 2, h - 2, radius - 1, radius - 1);
            ctx.clip();

            if (pressed) {
                const dark = ctx.createLinearGradient(0, 0, 0, h);
                dark.addColorStop(0, Qt.rgba(0, 0.02, 0.08, 0.45));
                dark.addColorStop(1, Qt.rgba(0, 0.02, 0.08, 0.1));
                ctx.fillStyle = dark;
                ctx.fillRect(0, 0, w, h);
            }

            const g = ctx.createRadialGradient(w / 2, h * 1.1, 0, w / 2, h * 1.1, Math.max(w * 0.62, h * 1.25));
            g.addColorStop(0, pressed ? Qt.rgba(0.55, 0.85, 1, 0.95) : Qt.rgba(0.72, 0.92, 1, 0.9));
            g.addColorStop(0.45, pressed ? Qt.rgba(0.3, 0.65, 0.95, 0.5) : Qt.rgba(0.45, 0.75, 1, 0.45));
            g.addColorStop(1, Qt.rgba(0.3, 0.6, 1, 0));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, w, h);

            if (!pressed) {
                const sheen = ctx.createLinearGradient(0, 0, 0, h * 0.5);
                sheen.addColorStop(0, Qt.rgba(1, 1, 1, 0.3));
                sheen.addColorStop(1, Qt.rgba(1, 1, 1, 0.06));
                ctx.fillStyle = sheen;
                ctx.fillRect(0, 0, w, h * 0.48);
            }

            ctx.restore();
        }
    }

    // ---- shell ---------------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.7)

        gradient: SplitGradient {
            split: 0.46
            splitEnd: 0.47
            colors: [
                Qt.rgba(1, 1, 1, 0.24),
                Qt.rgba(1, 1, 1, 0.1),
                Qt.rgba(0, 0, 0, 0.14),
                Qt.rgba(1, 1, 1, 0.08)
            ]
        }
    }

    SegmentGlow {
        width: root.mainWidth
        height: root.height
        fullWidth: root.width
        radius: root.radius
        pressed: mainMouse.pressed
        lit: mainMouse.containsMouse || mainMouse.pressed
    }

    SegmentGlow {
        x: root.mainWidth
        width: root.arrowWidth
        height: root.height
        fullWidth: root.width
        offsetX: root.mainWidth
        radius: root.radius
        pressed: arrowMouse.pressed || root.menuOpen
        lit: arrowMouse.containsMouse || pressed
    }

    // inner highlight: bright along the top, faint elsewhere
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius - 1
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, mainMouse.containsMouse || arrowMouse.containsMouse ? 0.38 : 0.2)

        Behavior on border.color {
            ColorAnimation {
                duration: 160
            }
        }
    }

    Rectangle {
        x: root.radius
        y: 1
        width: parent.width - root.radius * 2
        height: 1
        color: Qt.rgba(1, 1, 1, 0.5)
    }

    // split: a dark groove with a light edge
    Rectangle {
        x: root.mainWidth - 1
        y: 2
        width: 1
        height: parent.height - 4
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    Rectangle {
        x: root.mainWidth
        y: 2
        width: 1
        height: parent.height - 4
        color: Qt.rgba(1, 1, 1, 0.22)
    }

    // ---- content -------------------------------------------------------------------------------

    // white label with Win7's soft dark caption glow
    CaptionText {
        id: labelText
        x: (root.mainWidth - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: mainMouse.pressed ? 1 : 0
        text: root.label
        glow: 0.75
    }

    MediaGlyph {
        x: root.mainWidth + (root.arrowWidth - width) / 2 + 0.5
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: arrowMouse.pressed || root.menuOpen ? 1 : 0
        width: 5
        height: 9
        kind: "play"
        color: "white"
        shadowColor: Qt.rgba(0, 0, 0, 0.7)
    }

    MouseArea {
        id: mainMouse
        width: root.mainWidth
        height: root.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    MouseArea {
        id: arrowMouse
        x: root.mainWidth
        width: root.arrowWidth
        height: root.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.arrowClicked()
    }
}
