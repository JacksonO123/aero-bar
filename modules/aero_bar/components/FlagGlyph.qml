import QtQuick

Canvas {
    id: root

    property bool quiet: false

    implicitWidth: 18
    implicitHeight: 18

    onQuietChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height;
        if (w <= 0 || h <= 0) {
            return;
        }

        const flag = dy => {
            ctx.beginPath();
            ctx.moveTo(w * 0.24, h * 0.1 + dy);
            ctx.bezierCurveTo(w * 0.45, h * 0.0 + dy, w * 0.6, h * 0.22 + dy, w * 0.9, h * 0.1 + dy);
            ctx.lineTo(w * 0.9, h * 0.52 + dy);
            ctx.bezierCurveTo(w * 0.6, h * 0.64 + dy, w * 0.45, h * 0.42 + dy, w * 0.24, h * 0.52 + dy);
            ctx.closePath();
        };

        flag(1);
        ctx.fillStyle = "rgba(0,0,0,0.45)";
        ctx.fill();
        ctx.fillRect(w * 0.13, h * 0.08 + 1, w * 0.1, h * 0.86);

        const pole = ctx.createLinearGradient(w * 0.13, 0, w * 0.23, 0);
        pole.addColorStop(0, "#f4f6f8");
        pole.addColorStop(1, "#8a949e");
        ctx.fillStyle = pole;
        ctx.fillRect(w * 0.13, h * 0.08, w * 0.1, h * 0.86);

        flag(0);
        const g = ctx.createLinearGradient(0, 0, 0, h * 0.6);
        if (quiet) {
            g.addColorStop(0, "#c9ced4");
            g.addColorStop(1, "#7f8892");
        } else {
            g.addColorStop(0, "#ffffff");
            g.addColorStop(1, "#c5d2e0");
        }
        ctx.fillStyle = g;
        ctx.fill();
        ctx.lineWidth = 0.8;
        ctx.strokeStyle = "rgba(0,0,0,0.5)";
        ctx.stroke();

        if (quiet) {
            ctx.beginPath();
            ctx.arc(w * 0.74, h * 0.76, w * 0.2, 0, Math.PI * 2);
            ctx.fillStyle = "#ffe27a";
            ctx.fill();
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.arc(w * 0.84, h * 0.68, w * 0.18, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        }
    }
}
