import QtQuick
import "../../../utils/aurora.js" as Aurora

Canvas {
    id: root

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height;
        if (w <= 0 || h <= 0) {
            return;
        }

        let g = ctx.createLinearGradient(0, 0, 0, h);
        g.addColorStop(0, "#082650");
        g.addColorStop(0.5, "#1a5aa6");
        g.addColorStop(1, "#061d42");
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, w, h);

        g = ctx.createRadialGradient(w * 0.5, h * 0.42, 0, w * 0.5, h * 0.42, w * 0.55);
        g.addColorStop(0, "rgba(140,210,255,0.45)");
        g.addColorStop(0.5, "rgba(80,160,240,0.12)");
        g.addColorStop(1, "rgba(80,160,240,0)");
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, w, h);

        ctx.globalCompositeOperation = "lighter";
        const ribbon = (y0, y1, thick, bend, alpha) => Aurora.ribbon(ctx, w, h, y0, y1, thick, bend, alpha, "150,230,255", "120,220,255");
        ribbon(0.9, 0.35, 0.06, 0.12, 0.22);
        ribbon(0.98, 0.5, 0.1, 0.1, 0.14);
        ribbon(0.78, 0.18, 0.03, 0.16, 0.25);
        ribbon(1.05, 0.66, 0.05, 0.06, 0.12);

        const bubble = (x, y, r, alpha) => Aurora.bubble(ctx, w, h, x, y, r, alpha, "200,240,255");
        bubble(0.18, 0.22, h * 0.06, 0.12);
        bubble(0.82, 0.3, h * 0.04, 0.15);
        bubble(0.7, 0.75, h * 0.08, 0.08);
        bubble(0.3, 0.68, h * 0.03, 0.15);
        ctx.globalCompositeOperation = "source-over";

        g = ctx.createRadialGradient(w * 0.5, h * 0.5, h * 0.4, w * 0.5, h * 0.5, w * 0.75);
        g.addColorStop(0, "rgba(0,0,0,0)");
        g.addColorStop(1, "rgba(0,10,30,0.45)");
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, w, h);
    }
}
