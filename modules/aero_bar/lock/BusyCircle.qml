import QtQuick

// Win7's busy ring: a bright comet chasing round a faint circle.
Item {
    id: root

    property real size: 22
    property bool running: visible

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: ring
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = width / 2, r = width / 2 - 2;
            ctx.lineWidth = Math.max(2, width * 0.12);
            ctx.lineCap = "round";
            ctx.strokeStyle = "rgba(255,255,255,0.18)";
            ctx.beginPath();
            ctx.arc(c, c, r, 0, Math.PI * 2);
            ctx.stroke();
            const steps = 14;
            for (let i = 0; i < steps; i++) {
                ctx.strokeStyle = "rgba(170,230,255," + (i / steps) + ")";
                ctx.beginPath();
                ctx.arc(c, c, r, -Math.PI / 2 + i * 0.12, -Math.PI / 2 + (i + 1) * 0.12 + 0.02);
                ctx.stroke();
            }
        }

        RotationAnimation on rotation {
            running: root.running
            from: 0
            to: 360
            duration: 1100
            loops: Animation.Infinite
        }
    }
}
