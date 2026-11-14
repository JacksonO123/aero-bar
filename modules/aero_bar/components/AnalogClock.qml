import QtQuick

Item {
    id: root

    property var date: new Date()
    property real size: 128

    implicitWidth: size
    implicitHeight: size

    readonly property real center: size / 2
    readonly property real radius: size / 2

    component Hand: Item {
        id: hand

        property real target: 0
        property real center: 0
        property real length: 40
        property real tail: 0
        property real thickness: 3
        property color color: "black"
        property bool ticking: false

        // unwrapped so 354° -> 0° animates forward instead of spinning back
        property real angle: target
        onTargetChanged: angle += ((target - angle) % 360 + 540) % 360 - 180

        Behavior on angle {
            NumberAnimation {
                duration: hand.ticking ? 260 : 600
                easing.type: hand.ticking ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: 2.2
            }
        }

        x: center - thickness / 2
        y: center - length
        width: thickness
        height: length + tail

        transform: Rotation {
            origin.x: hand.thickness / 2
            origin.y: hand.length
            angle: hand.angle
        }

        Rectangle {
            anchors.fill: parent
            radius: hand.thickness / 2
            color: hand.color
            antialiasing: true
        }
    }

    Canvas {
        id: face
        anchors.fill: parent
        onWidthChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, r = w / 2, c = w / 2;
            if (r <= 0) {
                return;
            }

            const circle = (radius, fill) => {
                ctx.beginPath();
                ctx.arc(c, c, radius, 0, Math.PI * 2);
                ctx.fillStyle = fill;
                ctx.fill();
            };

            const bezel = ctx.createLinearGradient(0, 0, 0, w);
            bezel.addColorStop(0, "#ffffff");
            bezel.addColorStop(0.5, "#9fb0c2");
            bezel.addColorStop(1, "#eef3f8");
            circle(r, bezel);
            circle(r - 3, "#566a7f");

            const glow = ctx.createRadialGradient(c, c * 0.7, 0, c, c, r - 4);
            glow.addColorStop(0, "#ffffff");
            glow.addColorStop(0.65, "#eef6fc");
            glow.addColorStop(1, "#c3d8ea");
            circle(r - 4, glow);

            for (let i = 0; i < 60; i++) {
                const hour = i % 5 === 0;
                const a = i / 60 * Math.PI * 2;
                const inner = r - (hour ? 15 : 10);
                const outer = r - 8;
                ctx.beginPath();
                ctx.moveTo(c + Math.sin(a) * inner, c - Math.cos(a) * inner);
                ctx.lineTo(c + Math.sin(a) * outer, c - Math.cos(a) * outer);
                ctx.lineWidth = hour ? 2.6 : 1;
                ctx.lineCap = "round";
                ctx.strokeStyle = hour ? "#2a3d50" : "#93a4b5";
                ctx.stroke();
            }

            ctx.fillStyle = "#2a3d50";
            ctx.font = `bold ${Math.round(r * 0.17)}px sans-serif`;
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            const nr = r - 25;
            ctx.fillText("12", c, c - nr);
            ctx.fillText("3", c + nr, c);
            ctx.fillText("6", c, c + nr);
            ctx.fillText("9", c - nr, c);
        }
    }

    Hand {
        center: root.center
        target: (root.date.getHours() % 12) * 30 + root.date.getMinutes() * 0.5
        length: root.radius * 0.5
        tail: root.radius * 0.08
        thickness: 4.5
        color: "#1f2d3b"
    }

    Hand {
        center: root.center
        target: root.date.getMinutes() * 6 + root.date.getSeconds() * 0.1
        length: root.radius * 0.72
        tail: root.radius * 0.1
        thickness: 3
        color: "#2b3c4e"
    }

    Hand {
        center: root.center
        target: root.date.getSeconds() * 6
        length: root.radius * 0.8
        tail: root.radius * 0.2
        thickness: 1.5
        color: "#d3302a"
        ticking: true
    }

    Rectangle {
        anchors.centerIn: parent
        width: 9
        height: 9
        radius: 4.5
        border.width: 1
        border.color: "#6d0e0a"

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#ff8a7f"
            }
            GradientStop {
                position: 1
                color: "#b41d16"
            }
        }
    }

    Canvas {
        id: gloss
        anchors.fill: parent
        onWidthChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width;
            if (w <= 0) {
                return;
            }
            const g = ctx.createLinearGradient(0, w * 0.06, 0, w * 0.5);
            g.addColorStop(0, Qt.rgba(1, 1, 1, 0.75));
            g.addColorStop(1, Qt.rgba(1, 1, 1, 0.0));
            ctx.beginPath();
            ctx.ellipse(w * 0.16, w * 0.05, w * 0.68, w * 0.44);
            ctx.fillStyle = g;
            ctx.fill();
        }
    }
}
