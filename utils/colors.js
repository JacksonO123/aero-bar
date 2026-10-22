.pragma library

function interpolateColors(color1, color2, t) {
    let c1 = Qt.color(color1);
    let c2 = Qt.color(color2);
    
    let factor = Math.max(0.0, Math.min(1.0, t));

    let r = c1.r + (c2.r - c1.r) * factor;
    let g = c1.g + (c2.g - c1.g) * factor;
    let b = c1.b + (c2.b - c1.b) * factor;
    let a = c1.a + (c2.a - c1.a) * factor;

    return Qt.rgba(r, g, b, a);
}
