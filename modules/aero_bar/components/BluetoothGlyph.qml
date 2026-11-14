import QtQuick

GlassOrb {
    id: root

    property bool off: false

    size: 18
    lightColor: off ? "#e3e7eb" : "#9fe0ff"
    baseColor: off ? "#8a949e" : "#1f6fd8"
    darkColor: off ? "#3b434c" : "#062a6e"
    glowColor: Qt.rgba(0.75, 0.92, 1, 0.9)

    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            ctx.beginPath();
            ctx.moveTo(w * 0.33, h * 0.35);
            ctx.lineTo(w * 0.66, h * 0.64);
            ctx.lineTo(w * 0.5, h * 0.79);
            ctx.lineTo(w * 0.5, h * 0.21);
            ctx.lineTo(w * 0.66, h * 0.36);
            ctx.lineTo(w * 0.33, h * 0.65);
            ctx.lineWidth = Math.max(1.2, w * 0.08);
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.strokeStyle = "white";
            ctx.stroke();
        }
    }
}
