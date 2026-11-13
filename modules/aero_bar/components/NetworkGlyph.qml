import QtQuick

// Win7's network icons: five rising signal bars for Wi-Fi, or a monitor with its cable for a
// wired connection, with a red "not connected" or yellow "no internet" badge.
Canvas {
    id: root

    property string kind: "wired"     // "wired" | "wifi"
    property real strength: 1          // wifi bars lit, 0..1
    property string badge: ""          // "" | "warning" | "error"
    property bool onGlass: true        // white on the taskbar, blue in a flyout

    implicitWidth: 20
    implicitHeight: 18

    onKindChanged: requestPaint()
    // five bars: only repaint when the number lit changes, not on every 1% of signal
    readonly property int lit: badge === "error" ? 0 : Math.max(1, Math.ceil(strength * 5 - 0.001))
    onLitChanged: requestPaint()
    onOnGlassChanged: requestPaint()
    onBadgeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height;
        if (w <= 0 || h <= 0) {
            return;
        }

        if (kind === "wifi") {
            const n = 5, gap = w * 0.05, bw = (w * 0.86 - gap * (n - 1)) / n;
            for (let i = 0; i < n; i++) {
                const bh = h * (0.28 + 0.16 * i);
                const x = i * (bw + gap), y = h - bh;
                ctx.fillStyle = onGlass ? "rgba(0,0,0,0.45)" : "rgba(0,0,0,0.25)";
                ctx.fillRect(x + 0.5, y + 1, bw, bh);
                if (i < lit) {
                    const g = ctx.createLinearGradient(x, 0, x + bw, 0);
                    g.addColorStop(0, onGlass ? "#ffffff" : "#6fb7f5");
                    g.addColorStop(1, onGlass ? "#cfd8e2" : "#1f6fc9");
                    ctx.fillStyle = g;
                } else {
                    ctx.fillStyle = onGlass ? "rgba(255,255,255,0.25)" : "rgba(120,130,140,0.35)";
                }
                ctx.fillRect(x, y, bw, bh);
            }
        } else {
            // monitor
            const mx = w * 0.18, my = h * 0.06, mw = w * 0.78, mh = h * 0.62;
            ctx.fillStyle = onGlass ? "rgba(0,0,0,0.45)" : "rgba(0,0,0,0.2)";
            ctx.fillRect(mx + 0.5, my + 1, mw, mh);
            let g = ctx.createLinearGradient(0, my, 0, my + mh);
            g.addColorStop(0, "#e9eef3");
            g.addColorStop(1, "#8d98a4");
            ctx.fillStyle = g;
            ctx.fillRect(mx, my, mw, mh);
            g = ctx.createLinearGradient(0, my, 0, my + mh);
            g.addColorStop(0, "#9fdcff");
            g.addColorStop(0.5, "#3a8fe0");
            g.addColorStop(1, "#1557a8");
            ctx.fillStyle = g;
            ctx.fillRect(mx + w * 0.07, my + h * 0.08, mw - w * 0.14, mh - h * 0.16);
            // stand
            ctx.fillStyle = onGlass ? "#d9dfe5" : "#8d98a4";
            ctx.fillRect(mx + mw * 0.4, my + mh, mw * 0.2, h * 0.12);
            ctx.fillRect(mx + mw * 0.22, my + mh + h * 0.12, mw * 0.56, h * 0.08);
            // cable
            ctx.strokeStyle = onGlass ? "#ffffff" : "#5b6673";
            ctx.lineWidth = Math.max(1, w * 0.07);
            ctx.beginPath();
            ctx.moveTo(mx, my + mh * 0.6);
            ctx.lineTo(w * 0.06, my + mh * 0.6);
            ctx.lineTo(w * 0.06, h * 0.98);
            ctx.stroke();
        }

        if (badge !== "") {
            const r = w * 0.24, cx = w - r, cy = h - r;
            if (badge === "error") {
                const g = ctx.createRadialGradient(cx - r * 0.3, cy - r * 0.3, 0, cx, cy, r);
                g.addColorStop(0, "#ff9a85");
                g.addColorStop(1, "#c4210b");
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.fillStyle = g;
                ctx.fill();
                ctx.strokeStyle = "white";
                ctx.lineWidth = Math.max(1, r * 0.35);
                const d = r * 0.42;
                ctx.beginPath();
                ctx.moveTo(cx - d, cy - d);
                ctx.lineTo(cx + d, cy + d);
                ctx.moveTo(cx + d, cy - d);
                ctx.lineTo(cx - d, cy + d);
                ctx.stroke();
            } else {
                ctx.beginPath();
                ctx.moveTo(cx, cy - r * 1.1);
                ctx.lineTo(cx + r * 1.1, cy + r * 0.9);
                ctx.lineTo(cx - r * 1.1, cy + r * 0.9);
                ctx.closePath();
                const g = ctx.createLinearGradient(0, cy - r, 0, cy + r);
                g.addColorStop(0, "#fff3a0");
                g.addColorStop(1, "#f0b400");
                ctx.fillStyle = g;
                ctx.fill();
                ctx.strokeStyle = "rgba(90,60,0,0.8)";
                ctx.lineWidth = 0.8;
                ctx.stroke();
                ctx.fillStyle = "#3a2a00";
                ctx.fillRect(cx - 0.6, cy - r * 0.45, 1.2, r * 0.7);
                ctx.fillRect(cx - 0.6, cy + r * 0.38, 1.2, 1.2);
            }
        }
    }
}
