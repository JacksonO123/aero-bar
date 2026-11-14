import QtQuick

// Crisp transport glyphs (play / pause / prev / next) drawn in a unit box.
Canvas {
    id: root

    property string kind: "play"
    property color color: "white"
    property color shadowColor: Qt.rgba(0, 0, 0, 0.45)
    property bool shadow: true

    onKindChanged: requestPaint()
    onColorChanged: requestPaint()
    onShadowColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function shapes() {
        switch (kind) {
        case "pause":
            return [
                {
                    rect: [0.16, 0.1, 0.25, 0.8]
                },
                {
                    rect: [0.59, 0.1, 0.25, 0.8]
                }
            ];
        case "next":
            return [
                {
                    poly: [[0.04, 0.14], [0.44, 0.5], [0.04, 0.86]]
                },
                {
                    poly: [[0.42, 0.14], [0.82, 0.5], [0.42, 0.86]]
                },
                {
                    rect: [0.82, 0.14, 0.13, 0.72]
                }
            ];
        case "prev":
            return [
                {
                    poly: [[0.96, 0.14], [0.56, 0.5], [0.96, 0.86]]
                },
                {
                    poly: [[0.58, 0.14], [0.18, 0.5], [0.58, 0.86]]
                },
                {
                    rect: [0.05, 0.14, 0.13, 0.72]
                }
            ];
        default:
            return [
                {
                    poly: [[0.14, 0.06], [0.94, 0.5], [0.14, 0.94]]
                }
            ];
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height - (shadow ? 1 : 0);
        if (w <= 0 || h <= 0) {
            return;
        }

        const draw = (dy, fill) => {
            ctx.fillStyle = fill;
            for (const s of shapes()) {
                ctx.beginPath();
                if (s.rect) {
                    ctx.rect(s.rect[0] * w, s.rect[1] * h + dy, s.rect[2] * w, s.rect[3] * h);
                } else {
                    ctx.moveTo(s.poly[0][0] * w, s.poly[0][1] * h + dy);
                    for (let i = 1; i < s.poly.length; i++) {
                        ctx.lineTo(s.poly[i][0] * w, s.poly[i][1] * h + dy);
                    }
                    ctx.closePath();
                }
                ctx.fill();
            }
        };

        if (shadow) {
            draw(1, shadowColor);
        }
        draw(0, color);
    }
}
