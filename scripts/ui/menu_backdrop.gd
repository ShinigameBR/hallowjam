extends Control
## Painted main-menu backdrop: a cold sea, a patient moon and one lit window.

var _time := 0.0
var _stars: Array[Vector3] = []
var _motes: Array[Vector3] = []
var _rain: Array[Vector3] = []
var _vignette: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261031
	for i in range(90):
		_stars.append(Vector3(rng.randf(), rng.randf_range(0.02, 0.58), rng.randf_range(0.6, 2.0)))
	for i in range(26):
		_motes.append(Vector3(rng.randf(), rng.randf_range(0.35, 0.95), rng.randf_range(0.5, 1.6)))
	for i in range(70):
		_rain.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.4, 1.2)))
	_vignette = _build_vignette()


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var horizon := h * 0.62

	# sky
	var sky_top := Color("#06080f")
	var sky_mid := Color("#111827")
	var sky_low := Color("#26334a")
	for i in range(48):
		var t := float(i) / 47.0
		var c := sky_top.lerp(sky_mid, clampf(t * 1.8, 0.0, 1.0))
		c = c.lerp(sky_low, clampf((t - 0.55) / 0.45, 0.0, 1.0))
		draw_rect(Rect2(0, horizon * t, w, horizon / 47.0 + 1.0), c)

	# stars
	for star in _stars:
		var x := star.x * w
		var y := star.y * h
		var twinkle := 0.45 + 0.55 * absf(sin(_time * 0.7 + star.x * 31.0))
		var a := clampf(twinkle, 0.0, 1.0) * 0.75
		draw_circle(Vector2(x, y), star.z, Color(0.86, 0.9, 0.98, a * 0.8))
		if star.z > 1.7:
			draw_line(Vector2(x - 3, y), Vector2(x + 3, y), Color(0.86, 0.9, 0.98, a * 0.4), 0.8, true)

	# moon and its halo
	var moon := Vector2(w * 0.735, h * 0.235)
	var moon_r := minf(w, h) * 0.052
	for i in range(7):
		draw_circle(moon, moon_r * (1.9 + i * 0.35), Color(0.84, 0.78, 0.62, 0.018))
	draw_circle(moon, moon_r * 1.06, Color(0.93, 0.88, 0.75, 0.1))
	draw_circle(moon, moon_r, Color("#e8dfc8"))
	draw_circle(moon + Vector2(-moon_r * 0.22, -moon_r * 0.18), moon_r * 0.2, Color(0.86, 0.82, 0.7, 0.35))
	draw_circle(moon + Vector2(moon_r * 0.26, moon_r * 0.2), moon_r * 0.13, Color(0.86, 0.82, 0.7, 0.3))
	draw_circle(moon + Vector2(moon_r * 0.1, -moon_r * 0.35), moon_r * 0.09, Color(0.86, 0.82, 0.7, 0.25))

	# thin drifting clouds
	for i in range(5):
		var cx := fposmod(w * (0.1 + i * 0.23) + _time * (3.0 + i), w + w * 0.4) - w * 0.2
		var cy := h * (0.17 + i * 0.055)
		var cw := w * (0.22 + i * 0.03)
		var ch := h * 0.018
		draw_colored_polygon(_ellipse(cx, cy, cw, ch), Color(0.16, 0.2, 0.29, 0.24))
		draw_colored_polygon(_ellipse(cx + cw * 0.25, cy + ch * 0.8, cw * 0.7, ch * 0.7), Color(0.12, 0.16, 0.24, 0.2))

	# sea
	var sea_top := Color("#101b26")
	var sea_bottom := Color("#05090e")
	for i in range(30):
		var t := float(i) / 29.0
		var c := sea_top.lerp(sea_bottom, pow(t, 0.7))
		draw_rect(Rect2(0, horizon + (h - horizon) * t, w, (h - horizon) / 29.0 + 1.0), c)

	# moon reflection
	for i in range(24):
		var t := float(i) / 23.0
		var y := horizon + t * (h - horizon)
		var spread := w * (0.008 + t * 0.035)
		var a := (1.0 - t) * 0.16
		var shimmer := sin(_time * 1.3 + i * 0.9) * 0.5 + 0.5
		var x := moon.x + sin(_time * 0.6 + i * 1.7) * spread * 0.4
		draw_line(Vector2(x - spread * shimmer, y), Vector2(x + spread * shimmer, y), Color(0.85, 0.8, 0.66, a), maxf(1.0, h * 0.0015), true)

	# wave lines
	for i in range(18):
		var t := float(i) / 17.0
		var y := horizon + pow(t, 1.5) * (h - horizon) * 0.9
		var amp := 1.0 + t * 4.0
		var pts := PackedVector2Array()
		for j in range(0, 33):
			var x := w * float(j) / 32.0
			pts.append(Vector2(x, y + sin(x * 0.008 + _time * 0.8 + i) * amp))
		draw_polyline(pts, Color(0.55, 0.66, 0.72, 0.025 + t * 0.035), 1.0, true)

	# distant rock and cabin
	_draw_island(w, h, horizon)

	# foreground dock
	_draw_dock(w, h)

	# rain
	for drop in _rain:
		var x := fposmod(drop.x * w + _time * 18.0, w)
		var y := fposmod(drop.y * h + _time * 160.0 * drop.z, h)
		draw_line(Vector2(x, y), Vector2(x - 3, y + 12), Color(0.7, 0.78, 0.85, 0.05), 1.0, true)

	# gold motes
	for mote in _motes:
		var x := mote.x * w + sin(_time * 0.5 + mote.y * 20.0) * 12.0
		var y := fposmod(mote.y * h - _time * 9.0 * mote.z, h)
		var a := 0.12 + 0.1 * sin(_time * 1.1 + mote.x * 40.0)
		draw_circle(Vector2(x, y), mote.z, Color(0.84, 0.7, 0.42, a))

	# vignette
	draw_texture_rect(_vignette, Rect2(0, 0, w, h), false, Color(1, 1, 1, 1))


func _draw_island(w: float, h: float, horizon: float) -> void:
	var base_x := w * 0.78
	var base_y := horizon + h * 0.018
	var rock := PackedVector2Array([
		Vector2(base_x - w * 0.115, base_y),
		Vector2(base_x - w * 0.085, base_y - h * 0.02),
		Vector2(base_x - w * 0.04, base_y - h * 0.035),
		Vector2(base_x + w * 0.02, base_y - h * 0.028),
		Vector2(base_x + w * 0.09, base_y - h * 0.012),
		Vector2(base_x + w * 0.125, base_y),
	])
	draw_colored_polygon(rock, Color("#070b10"))

	var cabin_w := w * 0.075
	var cabin_h := h * 0.075
	var cx := base_x - cabin_w * 0.5
	var cy := base_y - h * 0.025 - cabin_h
	# body
	draw_rect(Rect2(cx, cy, cabin_w, cabin_h), Color("#080c11"))
	# roof
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - cabin_w * 0.1, cy + 2),
		Vector2(cx + cabin_w * 0.5, cy - cabin_h * 0.55),
		Vector2(cx + cabin_w * 1.1, cy + 2),
	]), Color("#06090d"))
	# chimney
	draw_rect(Rect2(cx + cabin_w * 0.68, cy - cabin_h * 0.45, cabin_w * 0.1, cabin_h * 0.35), Color("#06090d"))
	# lit window
	var flicker := 0.75 + 0.25 * sin(_time * 3.1) * sin(_time * 7.7)
	var win := Rect2(cx + cabin_w * 0.18, cy + cabin_h * 0.32, cabin_w * 0.22, cabin_h * 0.22)
	draw_rect(win.grow(4), Color(0.9, 0.66, 0.3, 0.08 * flicker))
	draw_rect(win, Color(0.92, 0.7, 0.36, 0.8 * flicker))
	draw_line(Vector2(win.position.x + win.size.x * 0.5, win.position.y), Vector2(win.position.x + win.size.x * 0.5, win.end.y), Color("#3a2712"), 1.0)
	# door
	draw_rect(Rect2(cx + cabin_w * 0.55, cy + cabin_h * 0.5, cabin_w * 0.2, cabin_h * 0.5), Color("#0b0f14"))
	# smoke
	for i in range(4):
		var t := float(i) / 3.0
		var sx := cx + cabin_w * 0.73 + sin(_time * 0.7 + i) * 6.0
		var sy := cy - cabin_h * 0.45 - t * h * 0.055
		draw_circle(Vector2(sx, sy), 3.0 + t * 6.0, Color(0.2, 0.24, 0.3, 0.1 * (1.0 - t)))


func _draw_dock(w: float, h: float) -> void:
	var y := h * 0.93
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.62, y),
		Vector2(w, y - h * 0.02),
		Vector2(w, h),
		Vector2(w * 0.55, h),
	]), Color("#05080c"))
	for i in range(5):
		var t := float(i) / 4.0
		var yy := lerpf(y, h, t)
		draw_line(Vector2(w * lerpf(0.62, 0.55, t), yy), Vector2(w, yy - h * 0.02 * (1.0 - t)), Color(0.18, 0.22, 0.27, 0.22), 1.2, true)
	# mooring post
	draw_rect(Rect2(w * 0.9, h * 0.84, w * 0.012, h * 0.1), Color("#060a0e"))
	draw_circle(Vector2(w * 0.906, h * 0.84), w * 0.009, Color("#060a0e"))
	draw_arc(Vector2(w * 0.9, h * 0.9), w * 0.03, -0.5, 1.4, 12, Color(0.35, 0.32, 0.25, 0.35), 2.0, true)


func _ellipse(cx: float, cy: float, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(24):
		var ang := TAU * float(i) / 24.0
		pts.append(Vector2(cx + cos(ang) * rx, cy + sin(ang) * ry))
	return pts


func _build_vignette() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0.05),
		Color(0, 0, 0, 0.62),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 512
	tex.height = 512
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	return tex
