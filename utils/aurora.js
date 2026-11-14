.pragma library

// Frutiger Aero light for a Canvas: soft ribbons sweeping up to the right, and out-of-focus
// bubbles. Paint them with ctx.globalCompositeOperation = "lighter" so they glow. Colours are
// "r,g,b" strings; positions and sizes are fractions of the canvas (w by h).

// a ribbon from the left edge at height y0 to the right edge at y1, `thick` tall, bowing by
// `bend`, brightest (`alpha`) along its middle in `core`, fading to `edge` at its sides
function ribbon(ctx, w, h, y0, y1, thick, bend, alpha, core, edge) {
  ctx.beginPath();
  ctx.moveTo(-w * 0.1, h * y0);
  ctx.bezierCurveTo(w * 0.3, h * (y0 - bend), w * 0.65, h * (y1 + bend), w * 1.1, h * y1);
  ctx.lineTo(w * 1.1, h * (y1 + thick));
  ctx.bezierCurveTo(w * 0.65, h * (y1 + bend + thick * 1.6), w * 0.3, h * (y0 - bend + thick * 0.6), -w * 0.1, h * (y0 + thick));
  ctx.closePath();
  const g = ctx.createLinearGradient(0, h * (y1 - 0.1), 0, h * (y0 + thick));
  g.addColorStop(0, "rgba(" + edge + ",0)");
  g.addColorStop(0.5, "rgba(" + core + "," + alpha + ")");
  g.addColorStop(1, "rgba(" + edge + ",0)");
  ctx.fillStyle = g;
  ctx.fill();
}

// a soft bubble at (x, y), `r` px across its glow, `alpha` at its centre
function bubble(ctx, w, h, x, y, r, alpha, rgb) {
  const g = ctx.createRadialGradient(w * x, h * y, 0, w * x, h * y, r);
  g.addColorStop(0, "rgba(" + rgb + "," + alpha + ")");
  g.addColorStop(1, "rgba(" + rgb + ",0)");
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(w * x, h * y, r, 0, Math.PI * 2);
  ctx.fill();
}

// a glassy bubble at (x, y), `r` px across: a clear body that thickens to a pale blue rim, and a
// glint at its top left (`alpha` is its overall strength)
function glassBubble(ctx, w, h, x, y, r, alpha) {
  const cx = w * x, cy = h * y;
  const body = ctx.createRadialGradient(cx, cy, r * 0.5, cx, cy, r);
  body.addColorStop(0, "rgba(255,255,255,0)");
  body.addColorStop(0.82, "rgba(255,255,255," + alpha * 0.45 + ")");
  body.addColorStop(1, "rgba(150,205,245," + alpha * 0.7 + ")");
  ctx.fillStyle = body;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.fill();

  ctx.strokeStyle = "rgba(70,150,215," + alpha * 0.4 + ")";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(cx, cy, r - 0.5, 0, Math.PI * 2);
  ctx.stroke();

  const glint = ctx.createRadialGradient(cx - r * 0.38, cy - r * 0.42, 0, cx - r * 0.38, cy - r * 0.42, r * 0.36);
  glint.addColorStop(0, "rgba(255,255,255," + alpha + ")");
  glint.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = glint;
  ctx.beginPath();
  ctx.arc(cx - r * 0.38, cy - r * 0.42, r * 0.36, 0, Math.PI * 2);
  ctx.fill();
}
