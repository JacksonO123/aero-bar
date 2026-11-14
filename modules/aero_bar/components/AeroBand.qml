import QtQuick
import "../../../utils/aurora.js" as Aurora

// The Frutiger Aero header band of the picker pages: a pale morning sky with soft ribbons of
// light and a few bubbles, glossy along its top and edged with a light rule. Put the heading and
// the like on top of it.
Item {
    id: root

    Canvas {
        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            if (w <= 0 || h <= 0) {
                return;
            }

            const sky = ctx.createLinearGradient(0, 0, 0, h);
            sky.addColorStop(0, "#fbfeff");
            sky.addColorStop(0.45, "#e2f3fe");
            sky.addColorStop(1, "#c4e5fa");
            ctx.fillStyle = sky;
            ctx.fillRect(0, 0, w, h);

            // light pooling on the right, behind the picture
            const pool = ctx.createRadialGradient(w * 0.87, h * 0.5, 0, w * 0.87, h * 0.5, w * 0.2);
            pool.addColorStop(0, "rgba(255,255,255,0.7)");
            pool.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = pool;
            ctx.fillRect(0, 0, w, h);

            // ribbons of light sweeping up to the right
            ctx.globalCompositeOperation = "lighter";
            const ribbon = (y0, y1, thick, bend, alpha) => Aurora.ribbon(ctx, w, h, y0, y1, thick, bend, alpha, "120,200,255", "160,220,255");
            ribbon(1.15, 0.2, 0.16, 0.22, 0.22);
            ribbon(1.3, 0.55, 0.22, 0.16, 0.16);
            ribbon(1.0, -0.05, 0.06, 0.3, 0.3);
            ctx.globalCompositeOperation = "source-over";

            // a few glassy bubbles drifting up, between the text and what sits on the right
            Aurora.glassBubble(ctx, w, h, 0.745, 0.6, h * 0.2, 0.9);
            Aurora.glassBubble(ctx, w, h, 0.795, 0.24, h * 0.1, 0.85);
            Aurora.glassBubble(ctx, w, h, 0.715, 0.22, h * 0.06, 0.8);
            Aurora.glassBubble(ctx, w, h, 0.805, 0.8, h * 0.07, 0.8);

            // gloss across the top
            const gloss = ctx.createLinearGradient(0, 0, 0, h * 0.42);
            gloss.addColorStop(0, "rgba(255,255,255,0.8)");
            gloss.addColorStop(1, "rgba(255,255,255,0)");
            ctx.fillStyle = gloss;
            ctx.fillRect(0, 0, w, h * 0.42);
        }
    }

    // a light rule along the bottom, with a white line under it like a bevel
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        width: parent.width
        height: 1
        color: "#9cc7e6"
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#ffffff"
    }
}
