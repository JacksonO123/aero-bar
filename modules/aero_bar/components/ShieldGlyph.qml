import QtQuick

Canvas {
    implicitWidth: 46
    implicitHeight: 54

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height;
        if (w <= 0 || h <= 0) {
            return;
        }
        const path = () => {
            ctx.beginPath();
            ctx.moveTo(w * 0.5, 1.5);
            ctx.bezierCurveTo(w * 0.68, h * 0.08, w * 0.85, h * 0.1, w - 1.5, h * 0.1);
            ctx.bezierCurveTo(w - 1.5, h * 0.55, w * 0.8, h * 0.82, w * 0.5, h - 1.5);
            ctx.bezierCurveTo(w * 0.2, h * 0.82, 1.5, h * 0.55, 1.5, h * 0.1);
            ctx.bezierCurveTo(w * 0.15, h * 0.1, w * 0.32, h * 0.08, w * 0.5, 1.5);
            ctx.closePath();
        };

        ctx.save();
        ctx.shadowColor = "rgba(0,20,60,0.45)";
        ctx.shadowBlur = 4;
        ctx.shadowOffsetY = 1.5;
        path();
        let g = ctx.createLinearGradient(0, 0, 0, h);
        g.addColorStop(0, "#ffe68a");
        g.addColorStop(1, "#c88a12");
        ctx.fillStyle = g;
        ctx.fill();
        ctx.restore();

        ctx.save();
        ctx.translate(w * 0.5, h * 0.5);
        ctx.scale(0.84, 0.86);
        ctx.translate(-w * 0.5, -h * 0.5);
        path();
        g = ctx.createLinearGradient(0, 0, 0, h);
        g.addColorStop(0, "#8fd6ff");
        g.addColorStop(0.5, "#2a7ad8");
        g.addColorStop(1, "#0b3a8a");
        ctx.fillStyle = g;
        ctx.fill();
        ctx.clip();
        g = ctx.createLinearGradient(0, 0, 0, h * 0.5);
        g.addColorStop(0, "rgba(255,255,255,0.7)");
        g.addColorStop(1, "rgba(255,255,255,0.08)");
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.ellipse(-w * 0.2, -h * 0.4, w * 1.1, h * 0.85);
        ctx.fill();
        ctx.restore();

        g = ctx.createLinearGradient(0, h * 0.35, 0, h * 0.75);
        g.addColorStop(0, "#fff3b8");
        g.addColorStop(1, "#e0a521");
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(w * 0.5, h * 0.44, w * 0.11, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.moveTo(w * 0.45, h * 0.47);
        ctx.lineTo(w * 0.55, h * 0.47);
        ctx.lineTo(w * 0.58, h * 0.7);
        ctx.lineTo(w * 0.42, h * 0.7);
        ctx.closePath();
        ctx.fill();
    }
}
