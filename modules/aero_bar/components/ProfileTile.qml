import QtQuick
import QtQuick.Effects
import "../../../utils/path.js" as PathUtils

// The Windows 7 user tile: a picture set in a thin, translucent glass bezel.
//
// The frame has two radii, like Win7's: rounded corners, and sides that bow out very slightly
// (`bow` px at the middle of each side). The picture is a plain square with small corners, so the
// glass is a little fuller at the middle of each side than near the corners. The picture is masked
// to its rounded shape. Setting `iconName` crossfades the picture to that icon (the start menu does
// this while a place on the right is hovered).
Item {
    id: root

    property string picture: ""     // file path of the user's picture; empty draws the default
    property string iconName: ""
    property real size: 66
    property real hoverT: 0

    property real bezel: 6          // glass width at the middle of a side (picture inset)
    property real cornerRadius: 8   // the frame's corners
    property real bow: 1.4          // how far each side bows out
    property real pictureRadius: 2.5

    readonly property real well: size - bezel * 2

    implicitWidth: size
    implicitHeight: size

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
        }
    }

    // ---- geometry ------------------------------------------------------------------------------
    //
    // Each side is an arc of radius R through the side's midpoint; each corner is a circle of
    // radius `cornerRadius` tangent to its two side arcs. Insetting the outline by d keeps every
    // centre and shrinks every radius by d, so the offset outlines used for the rims stay exact.

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
            // corner arc, top-left quadrant: from the left side's tangent to the top side's
            c0: Math.atan2(-a, -(a + d)),
            c1: Math.atan2(-(a + d), -a)
        };
    }

    // outline of the frame, inset by `inset` px, centred on (cx, cy)
    function framePath(ctx, cx, cy, inset) {
        const g = root.frameGeometry, i = inset ?? 0;
        const r = Math.max(0.01, g.r - i), R = g.R - i;
        const off = g.R - g.H;   // distance from the shape centre to a side arc's centre
        // quadrant k rotates (x, y) -> (-y, x) k times, and angles by k * 90deg
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

    // the picture's rounded square, grown by `grow` px
    function picturePath(ctx, ox, oy, grow) {
        const g = grow ?? 0;
        ctx.roundedRect(ox + root.bezel - g, oy + root.bezel - g, root.well + g * 2, root.well + g * 2, root.pictureRadius + g, root.pictureRadius + g);
    }

    // ---- glass bezel (and its shadow) ----------------------------------------------------------

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

            // soft drop shadow, then punch the frame out of it so it only falls outside
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

            // everything below stays inside the glass ring
            ctx.save();
            ctx.fillRule = Qt.OddEvenFill;
            ctx.beginPath();
            root.framePath(ctx, cx, cy, 0);
            root.picturePath(ctx, ox, oy, 0);
            ctx.clip();

            // body: translucent, silvery across the top, two-toned at the middle like Aero glass
            ctx.fillStyle = vgrad([[0.0, Qt.rgba(0.95, 0.98, 1, 0.92)], [0.12, Qt.rgba(0.86, 0.93, 1, 0.8)], [0.47, Qt.rgba(0.72, 0.84, 0.95, 0.64)], [0.5, Qt.rgba(0.44, 0.62, 0.79, 0.52)], [0.84, Qt.rgba(0.36, 0.56, 0.74, 0.5)], [1.0, Qt.rgba(0.46, 0.72, 0.9, 0.62)]]);
            ctx.fillRect(ox - 1, oy - 1, s + 2, s + 2);

            // a rounded glass rod catches light on both edges and is clearer through the
            // middle: darken a soft band halfway across the bezel
            strokeFrame(root.bezel * 0.55, root.bezel * 0.4, Qt.rgba(0.05, 0.16, 0.3, 0.12));

            // aqua light caught along the bottom edge
            strokeFrame(2.2, 2.2, vgrad([[0.0, Qt.rgba(0.35, 0.82, 1, 0)], [0.64, Qt.rgba(0.35, 0.82, 1, 0)], [1.0, Qt.rgba(0.35, 0.82, 1, 0.6)]]));
            ctx.restore();

            // outer edge: a dark line, a bright rim just inside it, and its fall-off
            strokeFrame(0.5, 1, Qt.rgba(0.02, 0.07, 0.16, 0.62));
            strokeFrame(1.5, 1, vgrad([[0.0, Qt.rgba(1, 1, 1, 0.95)], [0.5, Qt.rgba(1, 1, 1, 0.7)], [1.0, Qt.rgba(0.8, 0.96, 1, 0.75)]]));
            strokeFrame(2.5, 1, vgrad([[0.0, Qt.rgba(1, 1, 1, 0.4)], [0.5, Qt.rgba(1, 1, 1, 0.2)], [1.0, Qt.rgba(0.8, 0.96, 1, 0.12)]]));

            // inner edge: a soft light where the glass meets the picture, then the picture's
            // grey border
            strokePicture(1.5, 1, vgrad([[0.0, Qt.rgba(1, 1, 1, 0.62)], [0.5, Qt.rgba(0.94, 0.98, 1, 0.36)], [1.0, Qt.rgba(0.86, 0.93, 1, 0.3)]]));
            strokePicture(0.5, 1, Qt.rgba(0.5, 0.54, 0.56, 0.95));
        }
    }

    // ---- picture -------------------------------------------------------------------------------

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

                // person silhouette
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

        // hovered place icon, on a pale backdrop
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

        // glass reflection on the picture, strongest at the top-left
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
                // fades out before the ellipse's lower edge on the right, so only the curved
                // top-left part of the edge shows
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
