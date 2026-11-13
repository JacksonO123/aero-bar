import QtQuick

// Speaker with 0-3 sound waves depending on level, and a red Aero "no" badge when muted.
Canvas {
    id: root

    property real level: 0.5
    property bool muted: false
    property color color: "white"
    property color shadowColor: Qt.rgba(0, 0, 0, 0.5)
    property bool shadow: true

    readonly property int waves: muted || level <= 0.005 ? 0 : level < 0.34 ? 1 : level < 0.67 ? 2 : 3

    onWavesChanged: requestPaint()
    onMutedChanged: requestPaint()
    onColorChanged: requestPaint()
    onShadowColorChanged: requestPaint()
    onShadowChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height - (shadow ? 1 : 0);
        if (w <= 0 || h <= 0) {
            return;
        }

        const speaker = (dy, col) => {
            ctx.fillStyle = col;
            ctx.strokeStyle = col;
            ctx.beginPath();
            ctx.moveTo(0.04 * w, 0.35 * h + dy);
            ctx.lineTo(0.22 * w, 0.35 * h + dy);
            ctx.lineTo(0.46 * w, 0.1 * h + dy);
            ctx.lineTo(0.46 * w, 0.9 * h + dy);
            ctx.lineTo(0.22 * w, 0.65 * h + dy);
            ctx.lineTo(0.04 * w, 0.65 * h + dy);
            ctx.closePath();
            ctx.fill();

            ctx.lineWidth = Math.max(1.2, w * 0.075);
            ctx.lineCap = "round";
            for (let i = 0; i < root.waves; i++) {
                const r = w * (0.15 + i * 0.14);
                ctx.beginPath();
                ctx.arc(0.5 * w, 0.5 * h + dy, r, -Math.PI * 0.28, Math.PI * 0.28);
                ctx.stroke();
            }
        };

        if (shadow) {
            speaker(1, shadowColor);
        }
        speaker(0, color);

        if (muted) {
            const cx = 0.75 * w, cy = 0.62 * h, r = Math.min(w, h) * 0.24;
            const g = ctx.createLinearGradient(0, cy - r, 0, cy + r);
            g.addColorStop(0, "#ff8a7a");
            g.addColorStop(0.5, "#e2362a");
            g.addColorStop(1, "#a8120a");
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.fillStyle = g;
            ctx.fill();
            ctx.lineWidth = 1;
            ctx.strokeStyle = Qt.rgba(0.35, 0, 0, 0.8);
            ctx.stroke();

            const s = r * 0.45;
            ctx.strokeStyle = "white";
            ctx.lineWidth = Math.max(1.2, r * 0.32);
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(cx - s, cy - s);
            ctx.lineTo(cx + s, cy + s);
            ctx.moveTo(cx + s, cy - s);
            ctx.lineTo(cx - s, cy + s);
            ctx.stroke();
        }
    }
}
