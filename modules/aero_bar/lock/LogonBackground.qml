import QtQuick

// A deep-blue logon backdrop with soft aurora ribbons and a glow behind the user tile.
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

        // ribbons of light sweeping up to the right
        ctx.globalCompositeOperation = "lighter";
        const ribbon = (y0, y1, thick, bend, alpha) => {
            ctx.beginPath();
            ctx.moveTo(-w * 0.1, h * y0);
            ctx.bezierCurveTo(w * 0.3, h * (y0 - bend), w * 0.65, h * (y1 + bend), w * 1.1, h * y1);
            ctx.lineTo(w * 1.1, h * (y1 + thick));
            ctx.bezierCurveTo(w * 0.65, h * (y1 + bend + thick * 1.6), w * 0.3, h * (y0 - bend + thick * 0.6), -w * 0.1, h * (y0 + thick));
            ctx.closePath();
            const rg = ctx.createLinearGradient(0, h * (y1 - 0.1), 0, h * (y0 + thick));
            rg.addColorStop(0, "rgba(120,220,255,0)");
            rg.addColorStop(0.5, "rgba(150,230,255," + alpha + ")");
            rg.addColorStop(1, "rgba(120,220,255,0)");
            ctx.fillStyle = rg;
            ctx.fill();
        };
        ribbon(0.9, 0.35, 0.06, 0.12, 0.22);
        ribbon(0.98, 0.5, 0.1, 0.1, 0.14);
        ribbon(0.78, 0.18, 0.03, 0.16, 0.25);
        ribbon(1.05, 0.66, 0.05, 0.06, 0.12);

        // a few out-of-focus bubbles
        const bubble = (x, y, r, a) => {
            const bg = ctx.createRadialGradient(w * x, h * y, 0, w * x, h * y, r);
            bg.addColorStop(0, "rgba(200,240,255," + a + ")");
            bg.addColorStop(1, "rgba(200,240,255,0)");
            ctx.fillStyle = bg;
            ctx.beginPath();
            ctx.arc(w * x, h * y, r, 0, Math.PI * 2);
            ctx.fill();
        };
        bubble(0.18, 0.22, h * 0.06, 0.12);
        bubble(0.82, 0.3, h * 0.04, 0.15);
        bubble(0.7, 0.75, h * 0.08, 0.08);
        bubble(0.3, 0.68, h * 0.03, 0.15);
        ctx.globalCompositeOperation = "source-over";

        // vignette
        g = ctx.createRadialGradient(w * 0.5, h * 0.5, h * 0.4, w * 0.5, h * 0.5, w * 0.75);
        g.addColorStop(0, "rgba(0,0,0,0)");
        g.addColorStop(1, "rgba(0,10,30,0.45)");
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, w, h);
    }
}
