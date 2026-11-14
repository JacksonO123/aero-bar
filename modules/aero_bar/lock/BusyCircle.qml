import QtQuick

Item {
    id: root

    property real size: 22
    property bool running: visible

    implicitWidth: size
    implicitHeight: size

    Canvas {
        anchors.fill: parent

        onWidthChanged: requestPaint()

        // dots, not segments: overlapping translucent strokes leave seams
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = width / 2;
            const w = Math.max(2, width * 0.12);
            const r = c - w * 1.25;
            if (r <= 0) {
                return;
            }

            ctx.lineWidth = w;
            ctx.strokeStyle = "rgba(170,225,255,0.16)";
            ctx.beginPath();
            ctx.arc(c, c, r, 0, Math.PI * 2);
            ctx.stroke();

            const head = -Math.PI / 2;
            const span = Math.PI * 1.6;
            const dots = Math.ceil(r * span);
            for (let i = 0; i <= dots; i++) {
                const t = i / dots;
                const a = head - span * (1 - t);
                ctx.fillStyle = `rgba(${Math.round(40 + 200 * t)},${Math.round(160 + 90 * t)},255,${0.5 * Math.pow(t, 1.8)})`;
                ctx.beginPath();
                ctx.arc(c + r * Math.cos(a), c + r * Math.sin(a), w / 2 * (0.35 + 0.65 * t), 0, Math.PI * 2);
                ctx.fill();
            }

            const hx = c + r * Math.cos(head), hy = c + r * Math.sin(head);
            const glow = ctx.createRadialGradient(hx, hy, 0, hx, hy, w * 1.25);
            glow.addColorStop(0, "rgba(255,255,255,1)");
            glow.addColorStop(0.4, "rgba(200,242,255,0.85)");
            glow.addColorStop(1, "rgba(120,210,255,0)");
            ctx.fillStyle = glow;
            ctx.beginPath();
            ctx.arc(hx, hy, w * 1.25, 0, Math.PI * 2);
            ctx.fill();
        }

        RotationAnimator on rotation {
            running: root.running
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
        }
    }
}
