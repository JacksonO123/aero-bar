import QtQuick
import QtQuick.Effects
import "../../../utils/path.js" as PathUtils

Item {
    id: root

    property string picture: ""
    property string iconName: ""
    property real size: 66
    property real hoverT: 0

    property real bezel: 6
    property real cornerRadius: 8
    property real bow: 1.4
    property real pictureRadius: 2.5

    readonly property real well: size - bezel * 2

    implicitWidth: size
    implicitHeight: size

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
        }
    }

    // sides: arcs of radius R through their midpoints; corners: tangent circles
    readonly property var frameGeometry: {
        const H = root.size / 2;
        const r = Math.min(root.cornerRadius, H);
        const s = Math.max(0.01, root.bow);
        const R = (H * H + s * s) / (2 * s);
        const d = R - H;
        const a = (-d + Math.sqrt(2 * (R - r) * (R - r) - d * d)) / 2;
        return {
            H: H,
            r: r,
            R: R,
            a: a,
            // top-left corner arc: from the left side's tangent point to the top side's
            c0: Math.atan2(-a, -(a + d)),
            c1: Math.atan2(-(a + d), -a)
        };
    }

    function framePath(ctx, cx, cy, inset) {
        const g = root.frameGeometry, i = inset ?? 0;
        const r = Math.max(0.01, g.r - i), R = g.R - i;
        const off = g.R - g.H; // shape centre to a side arc's centre
        const rot = (k, x, y) => {
            for (let n = 0; n < k; n++) {
                const t = x;
                x = -y;
                y = t;
            }
            return [cx + x, cy + y];
        };
        ctx.moveTo(...rot(0, -g.a + r * Math.cos(g.c0), -g.a + r * Math.sin(g.c0)));
        for (let k = 0; k < 4; k++) {
            const q = k * Math.PI / 2;
            const cc = rot(k, -g.a, -g.a);
            ctx.arc(cc[0], cc[1], r, g.c0 + q, g.c1 + q, false);
            const sc = rot(k, 0, off);
            ctx.arc(sc[0], sc[1], R, g.c1 + q, -Math.PI - g.c1 + q, false);
        }
        ctx.closePath();
    }

    function picturePath(ctx, ox, oy, grow) {
        const g = grow ?? 0;
        ctx.roundedRect(ox + root.bezel - g, oy + root.bezel - g, root.well + g * 2, root.well + g * 2, root.pictureRadius + g, root.pictureRadius + g);
    }

    Canvas {
        id: ring

        readonly property real pad: 10

        x: -pad
        y: -pad
        width: root.width + pad * 2
        height: root.height + pad * 2
        onWidthChanged: requestPaint()

        Connections {
            target: root
            function onFrameGeometryChanged() {
                ring.requestPaint();
            }
            function onBezelChanged() {
                ring.requestPaint();
            }
            function onPictureRadiusChanged() {
                ring.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const s = root.size;
            if (s <= 0) {
                return;
            }
            const ox = pad, oy = pad, cx = ox + s / 2, cy = oy + s / 2;
            const vgrad = stops => {
                const g = ctx.createLinearGradient(0, oy, 0, oy + s);
                for (const st of stops) {
                    g.addColorStop(st[0], st[1]);
                }
                return g;
            };
            const strokeFrame = (inset, width, style) => {
                ctx.beginPath();
                root.framePath(ctx, cx, cy, inset);
                ctx.lineJoin = "round";
                ctx.lineWidth = width;
                ctx.strokeStyle = style;
                ctx.stroke();
            };
            const strokePicture = (grow, width, style) => {
                ctx.beginPath();
                root.picturePath(ctx, ox, oy, grow);
                ctx.lineWidth = width;
                ctx.strokeStyle = style;
                ctx.stroke();
            };

            ctx.save();
            ctx.shadowColor = Qt.rgba(0, 0.02, 0.08, 0.55);
            ctx.shadowBlur = 8;
            ctx.shadowOffsetY = 1.5;
            ctx.beginPath();
            root.framePath(ctx, cx, cy, 0);
            ctx.fillStyle = "black";
            ctx.fill();
            ctx.restore();

            ctx.save();
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            root.framePath(ctx, cx, cy, 0);
            ctx.fill();
            ctx.restore();

            ctx.save();
            ctx.fillRule = Qt.OddEvenFill;
            ctx.beginPath();
            root.framePath(ctx, cx, cy, 0);
            root.picturePath(ctx, ox, oy, 0);
            ctx.clip();

            ctx.fillStyle = vgrad([[0.0, Qt.rgba(0.95, 0.98, 1, 0.92)], [0.12, Qt.rgba(0.86, 0.93, 1, 0.8)], [0.47, Qt.rgba(0.72, 0.84, 0.95, 0.64)], [0.5, Qt.rgba(0.44, 0.62, 0.79, 0.52)], [0.84, Qt.rgba(0.36, 0.56, 0.74, 0.5)], [1.0, Qt.rgba(0.46, 0.72, 0.9, 0.62)]]);
            ctx.fillRect(ox - 1, oy - 1, s + 2, s + 2);

            strokeFrame(root.bezel * 0.55, root.bezel * 0.4, Qt.rgba(0.05, 0.16, 0.3, 0.12));

            strokeFrame(2.2, 2.2, vgrad([[0.0, Qt.rgba(0.35, 0.82, 1, 0)], [0.64, Qt.rgba(0.35, 0.82, 1, 0)], [1.0, Qt.rgba(0.35, 0.82, 1, 0.6)]]));
            ctx.restore();

            strokeFrame(0.5, 1, Qt.rgba(0.02, 0.07, 0.16, 0.62));
            strokeFrame(1.5, 1, vgrad([[0.0, Qt.rgba(1, 1, 1, 0.95)], [0.5, Qt.rgba(1, 1, 1, 0.7)], [1.0, Qt.rgba(0.8, 0.96, 1, 0.75)]]));
            strokeFrame(2.5, 1, vgrad([[0.0, Qt.rgba(1, 1, 1, 0.4)], [0.5, Qt.rgba(1, 1, 1, 0.2)], [1.0, Qt.rgba(0.8, 0.96, 1, 0.12)]]));

            strokePicture(1.5, 1, vgrad([[0.0, Qt.rgba(1, 1, 1, 0.62)], [0.5, Qt.rgba(0.94, 0.98, 1, 0.36)], [1.0, Qt.rgba(0.86, 0.93, 1, 0.3)]]));
            strokePicture(0.5, 1, Qt.rgba(0.5, 0.54, 0.56, 0.95));
        }
    }

    Item {
        id: pictureWell
        x: root.bezel
        y: root.bezel
        width: root.well
        height: root.well

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: wellMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        Rectangle {
            anchors.fill: parent
            color: "#1f3a57"
        }

        Canvas {
            id: defaultPicture
            anchors.fill: parent
            visible: root.picture === "" || userImage.status === Image.Error
            onWidthChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height;
                if (w <= 0) {
                    return;
                }

                const sky = ctx.createLinearGradient(0, 0, 0, h);
                sky.addColorStop(0, "#9fe2ff");
                sky.addColorStop(0.6, "#2f8fe0");
                sky.addColorStop(1, "#0d4f9c");
                ctx.fillStyle = sky;
                ctx.fillRect(0, 0, w, h);

                const bubble = (cx, cy, r) => {
                    const g = ctx.createRadialGradient(cx - r * 0.3, cy - r * 0.3, 0, cx, cy, r);
                    g.addColorStop(0, Qt.rgba(1, 1, 1, 0.9));
                    g.addColorStop(0.7, Qt.rgba(1, 1, 1, 0.12));
                    g.addColorStop(1, Qt.rgba(1, 1, 1, 0.35));
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    ctx.fillStyle = g;
                    ctx.fill();
                };
                bubble(w * 0.18, h * 0.22, w * 0.1);
                bubble(w * 0.84, h * 0.3, w * 0.07);

                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.92);
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.4, w * 0.17, 0, Math.PI * 2);
                ctx.fill();
                ctx.beginPath();
                ctx.ellipse(w * 0.18, h * 0.64, w * 0.64, h * 0.6);
                ctx.fill();
            }
        }

        Image {
            id: userImage
            anchors.fill: parent
            visible: root.picture !== ""
            source: PathUtils.fileUrl(root.picture)
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.well * 2, root.well * 2)
            asynchronous: true
            cache: false
            mipmap: true
        }

        Rectangle {
            anchors.fill: parent
            opacity: root.iconName !== "" ? 1 : 0

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1
                    color: "#d6e7f5"
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            ImageIcon {
                anchors.centerIn: parent
                size: root.well * 0.72
                desktopIcon: root.iconName
                visible: root.iconName !== "" || parent.opacity > 0
            }
        }

        Canvas {
            anchors.fill: parent
            opacity: 0.85 + 0.15 * root.hoverT
            onWidthChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height;
                if (w <= 0) {
                    return;
                }
                // fade out before the ellipse's lower-right edge so only its top-left curve shows
                const g = ctx.createLinearGradient(0, 0, w * 0.7, h * 0.7);
                g.addColorStop(0, Qt.rgba(1, 1, 1, 0.55));
                g.addColorStop(0.4, Qt.rgba(1, 1, 1, 0.14));
                g.addColorStop(0.72, Qt.rgba(1, 1, 1, 0));
                ctx.beginPath();
                ctx.ellipse(-w * 0.55, -h * 0.75, w * 1.55, h * 1.3);
                ctx.fillStyle = g;
                ctx.fill();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.1 * root.hoverT)
        }
    }

    Rectangle {
        id: wellMask
        width: root.well
        height: root.well
        radius: root.pictureRadius
        antialiasing: true
        visible: false
        layer.enabled: true
    }
}
