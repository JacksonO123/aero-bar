import QtQuick

Canvas {
    id: root

    property bool quiet: false

    implicitWidth: 25
    implicitHeight: 24

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

        const body = dy => {
            ctx.beginPath();
            ctx.moveTo(w * 0.20, h * 0.66 + dy);
            ctx.bezierCurveTo(w * 0.28, h * 0.62 + dy, w * 0.30, h * 0.54 + dy, w * 0.30, h * 0.44 + dy);
            ctx.bezierCurveTo(w * 0.30, h * 0.28 + dy, w * 0.38, h * 0.20 + dy, w * 0.50, h * 0.20 + dy);
            ctx.bezierCurveTo(w * 0.62, h * 0.20 + dy, w * 0.70, h * 0.28 + dy, w * 0.70, h * 0.44 + dy);
            ctx.bezierCurveTo(w * 0.70, h * 0.54 + dy, w * 0.72, h * 0.62 + dy, w * 0.80, h * 0.66 + dy);
            ctx.closePath();
        };

        const clapper = dy => {
            ctx.beginPath();
            ctx.arc(w * 0.50, h * 0.66 + dy, w * 0.11, 0, Math.PI);
            ctx.closePath();
        };

        const paint = dy => {
            body(dy);
            ctx.fill();
            clapper(dy);
            ctx.fill();
        };

        ctx.fillStyle = "rgba(0,0,0,0.45)";
        paint(1);

        const g = ctx.createLinearGradient(0, 0, 0, h * 0.75);
        if (quiet) {
            g.addColorStop(0, "#c9ced4");
            g.addColorStop(1, "#7f8892");
        } else {
            g.addColorStop(0, "#ffffff");
            g.addColorStop(1, "#c5d2e0");
        }
        ctx.fillStyle = g;
        paint(0);

        ctx.lineWidth = 0.8;
        ctx.strokeStyle = "rgba(0,0,0,0.5)";
        body(0);
        ctx.stroke();
        clapper(0);
        ctx.stroke();
    }
}
