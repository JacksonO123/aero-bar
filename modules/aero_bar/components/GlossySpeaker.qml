import QtQuick

Canvas {
    id: root

    property bool muted: false

    implicitWidth: 32
    implicitHeight: 40

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onMutedChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height;
        if (w <= 0 || h <= 0) {
            return;
        }

        const r = w * 0.16;

        const body = ctx.createLinearGradient(0, 0, w, 0);
        body.addColorStop(0, "#56677a");
        body.addColorStop(0.5, "#2a3440");
        body.addColorStop(1, "#141a21");
        ctx.beginPath();
        ctx.roundedRect(0.5, 0.5, w - 1, h - 1, r, r);
        ctx.fillStyle = body;
        ctx.fill();
        ctx.lineWidth = 1;
        ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.75);
        ctx.stroke();

        const driver = (cx, cy, radius) => {
            const g = ctx.createRadialGradient(cx - radius * 0.25, cy - radius * 0.3, 0, cx, cy, radius);
            g.addColorStop(0, root.muted ? "#d7dbe0" : "#f2f8fd");
            g.addColorStop(0.45, root.muted ? "#8c949c" : "#8fa7bd");
            g.addColorStop(0.85, "#2c3640");
            g.addColorStop(1, "#11161b");
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, Math.PI * 2);
            ctx.fillStyle = g;
            ctx.fill();

            const cap = ctx.createRadialGradient(cx - radius * 0.1, cy - radius * 0.12, 0, cx, cy, radius * 0.34);
            cap.addColorStop(0, "#ffffff");
            cap.addColorStop(1, root.muted ? "#7d858d" : "#6e8aa3");
            ctx.beginPath();
            ctx.arc(cx, cy, radius * 0.34, 0, Math.PI * 2);
            ctx.fillStyle = cap;
            ctx.fill();
        };

        driver(w / 2, h * 0.24, w * 0.15);
        driver(w / 2, h * 0.64, w * 0.32);

        ctx.save();
        ctx.beginPath();
        ctx.roundedRect(1, 1, w - 2, h - 2, r, r);
        ctx.clip();
        const gloss = ctx.createLinearGradient(0, 0, 0, h * 0.5);
        gloss.addColorStop(0, Qt.rgba(1, 1, 1, 0.45));
        gloss.addColorStop(1, Qt.rgba(1, 1, 1, 0.02));
        ctx.beginPath();
        ctx.ellipse(-w * 0.2, -h * 0.25, w * 1.4, h * 0.7);
        ctx.fillStyle = gloss;
        ctx.fill();
        ctx.restore();
    }
}
