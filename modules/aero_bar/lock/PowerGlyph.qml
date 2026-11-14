import QtQuick

Canvas {
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height, c = w / 2, r = w * 0.32;
        const draw = (dy, col) => {
            ctx.strokeStyle = col;
            ctx.lineWidth = Math.max(1.6, w * 0.12);
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(c, h / 2 + dy + w * 0.04, r, -Math.PI / 2 + 0.75, Math.PI * 1.5 - 0.75);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(c, h * 0.16 + dy);
            ctx.lineTo(c, h * 0.5 + dy);
            ctx.stroke();
        };
        draw(1, "rgba(60,0,0,0.5)");
        draw(0, "white");
    }
}
