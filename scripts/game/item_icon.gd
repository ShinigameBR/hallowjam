extends Control
## Draws every inventory item with simple vector shapes.
## Keeps the prototype asset-free without falling back to emoji.

var item_id: String = ""
var glow: bool = false


func setup(id: String, with_glow: bool = false) -> void:
	item_id = id
	glow = with_glow
	queue_redraw()


func _draw() -> void:
	if item_id == "":
		return
	var data := ItemDB.item(item_id)
	if data.is_empty():
		return
	var s := minf(size.x, size.y)
	if s <= 0.0:
		return

	var base: Color = data.get("color", UI.MUTED)
	if glow:
		draw_circle(Vector2(size.x * 0.5, size.y * 0.5), minf(size.x, size.y) * 0.42, Color(base, 0.14))
		draw_circle(Vector2(size.x * 0.5, size.y * 0.5), minf(size.x, size.y) * 0.31, Color(base, 0.08))

	var texture_path := String(data.get("texture", ""))
	if texture_path != "":
		var texture := load(texture_path) as Texture2D
		if texture != null:
			var tex_size := texture.get_size()
			if tex_size.x > 0.0 and tex_size.y > 0.0:
				var fit := minf(size.x / tex_size.x, size.y / tex_size.y) * 0.86
				var draw_size := tex_size * fit
				var pos := (size - draw_size) * 0.5
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_texture_rect(texture, Rect2(pos, draw_size), false)
			return

	var origin := (size - Vector2(s, s)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(s / 64.0, s / 64.0))
	_draw_icon(String(data.get("icon", "stone")), base)


func _draw_icon(icon: String, base: Color) -> void:
	match icon:
		"mushroom":
			draw_rect(Rect2(26, 32, 12, 22), Color("#d8cbb4"))
			draw_rect(Rect2(26, 32, 5, 22), Color("#c4b69c"))
			var cap := _ellipse_points(32, 32, 24, 16, 20, PI, TAU)
			draw_colored_polygon(cap, base)
			draw_circle(Vector2(24, 24), 3.2, Color(base.lightened(0.35), 0.8))
			draw_circle(Vector2(39, 21), 2.4, Color(base.lightened(0.35), 0.8))
			draw_circle(Vector2(33, 28), 2.0, Color(base.lightened(0.35), 0.7))
		"moss":
			draw_circle(Vector2(24, 38), 11, base.darkened(0.18))
			draw_circle(Vector2(38, 40), 12, base)
			draw_circle(Vector2(33, 29), 10, base.lightened(0.08))
			draw_circle(Vector2(45, 32), 8, base.darkened(0.1))
			for p in [Vector2(23, 29), Vector2(34, 22), Vector2(43, 27)]:
				draw_circle(p, 2.2, Color("#e8e3d4"))
				draw_circle(p, 1.0, Color("#d6b36a"))
		"algae":
			for i in range(3):
				var pts := PackedVector2Array()
				var x := 20.0 + i * 10.0
				for y in range(18, 58, 4):
					pts.append(Vector2(x + sin(float(y) * 0.22 + i) * 5.0, float(y)))
				draw_polyline(pts, base.darkened(0.1 * i), 4.0 - i * 0.5, true)
			draw_circle(Vector2(25, 24), 4.0, base.lightened(0.15))
			draw_circle(Vector2(39, 33), 3.0, base.lightened(0.2))
		"feather":
			var pts := PackedVector2Array([
				Vector2(46, 12), Vector2(38, 22), Vector2(30, 30),
				Vector2(22, 42), Vector2(17, 54), Vector2(20, 55),
				Vector2(29, 43), Vector2(36, 34), Vector2(43, 25),
			])
			draw_colored_polygon(pts, base)
			draw_line(Vector2(18, 55), Vector2(47, 12), base.darkened(0.35), 1.6, true)
			for i in range(5):
				var t := 0.2 + i * 0.14
				var a := Vector2(18, 55).lerp(Vector2(47, 12), t)
				draw_line(a, a + Vector2(-7, -5), Color(base.darkened(0.2), 0.7), 1.0, true)
				draw_line(a, a + Vector2(6, 5), Color(base.darkened(0.2), 0.7), 1.0, true)
		"flower":
			draw_line(Vector2(32, 58), Vector2(32, 30), Color("#5f8a5a"), 2.5, true)
			draw_colored_polygon(PackedVector2Array([
				Vector2(32, 44), Vector2(22, 38), Vector2(20, 45), Vector2(30, 48)
			]), Color("#5f8a5a"))
			for i in range(5):
				var ang := -PI * 0.5 + TAU * float(i) / 5.0
				var p := Vector2(32, 25) + Vector2(cos(ang), sin(ang)) * 10.0
				draw_circle(p, 7.0, base)
			draw_circle(Vector2(32, 25), 5.0, Color("#d6b36a"))
		"shell":
			var pts := PackedVector2Array()
			pts.append(Vector2(32, 52))
			for i in range(13):
				var ang := PI + PI * float(i) / 12.0
				pts.append(Vector2(32, 44) + Vector2(cos(ang) * 22.0, sin(ang) * 24.0))
			pts.append(Vector2(32, 52))
			draw_colored_polygon(pts, base)
			for i in range(5):
				var ang := PI + PI * (float(i) + 0.5) / 5.0
				draw_line(Vector2(32, 50), Vector2(32, 44) + Vector2(cos(ang) * 20.0, sin(ang) * 22.0), base.darkened(0.3), 1.3, true)
			draw_circle(Vector2(32, 50), 3.0, base.darkened(0.35))
		"stone":
			draw_colored_polygon(PackedVector2Array([
				Vector2(16, 40), Vector2(22, 24), Vector2(36, 17),
				Vector2(49, 27), Vector2(52, 43), Vector2(40, 52), Vector2(24, 51)
			]), base)
			draw_colored_polygon(PackedVector2Array([
				Vector2(22, 24), Vector2(36, 17), Vector2(39, 31), Vector2(29, 37)
			]), base.lightened(0.18))
			draw_line(Vector2(39, 31), Vector2(52, 43), base.darkened(0.25), 1.5, true)
			draw_line(Vector2(29, 37), Vector2(24, 51), base.darkened(0.2), 1.5, true)
		"fish":
			var body := _ellipse_points(33, 34, 19, 12, 18, 0, TAU)
			draw_colored_polygon(body, base)
			draw_colored_polygon(PackedVector2Array([
				Vector2(15, 34), Vector2(5, 24), Vector2(7, 34), Vector2(5, 44)
			]), base.darkened(0.15))
			draw_circle(Vector2(43, 30), 2.2, UI.BG)
			draw_line(Vector2(30, 27), Vector2(30, 41), base.darkened(0.18), 1.2, true)
			draw_arc(Vector2(33, 34), 13, -0.9, 0.9, 10, base.darkened(0.2), 1.0, true)
		"can":
			draw_rect(Rect2(20, 18, 25, 38), base)
			draw_rect(Rect2(20, 18, 25, 8), base.lightened(0.18))
			draw_rect(Rect2(20, 48, 25, 8), base.darkened(0.18))
			draw_rect(Rect2(24, 30, 17, 12), Color("#7d3f46"))
			draw_circle(Vector2(32, 36), 3.0, Color("#d6b36a"))
			draw_line(Vector2(45, 22), Vector2(52, 16), base.lightened(0.4), 2.0, true)
			draw_circle(Vector2(53, 15), 2.5, base.lightened(0.4))
		"meat":
			draw_circle(Vector2(30, 30), 15, base)
			draw_circle(Vector2(38, 38), 11, base.darkened(0.08))
			draw_line(Vector2(40, 42), Vector2(52, 54), Color("#e6d8c3"), 6.0, true)
			draw_circle(Vector2(53, 55), 4.5, Color("#efe3cf"))
			draw_circle(Vector2(26, 24), 4.0, Color(base.lightened(0.18), 0.8))
			draw_circle(Vector2(34, 35), 2.0, Color("#f0dfc9", 0.65))
		"water":
			draw_colored_polygon(PackedVector2Array([
				Vector2(32, 10), Vector2(45, 33), Vector2(45, 44),
				Vector2(38, 53), Vector2(26, 53), Vector2(19, 44), Vector2(19, 33)
			]), base)
			draw_circle(Vector2(32, 42), 9.0, base.lightened(0.1))
			draw_arc(Vector2(32, 41), 10.0, PI * 1.1, PI * 1.45, 8, Color(1, 1, 1, 0.5), 1.6, true)
		"potion":
			draw_rect(Rect2(27, 12, 10, 10), Color("#8a6a4a"))
			draw_rect(Rect2(28, 21, 8, 8), Color("#c8d0d6"))
			draw_circle(Vector2(32, 42), 16, Color(base.darkened(0.1), 0.95))
			draw_rect(Rect2(24, 28, 16, 20), base.darkened(0.1))
			draw_circle(Vector2(32, 42), 12, base)
			draw_circle(Vector2(28, 38), 3.0, Color(1, 1, 1, 0.45))
			draw_line(Vector2(23, 33), Vector2(41, 33), Color(1, 1, 1, 0.18), 1.0, true)
		"syringe_empty", "syringe_water", "syringe_tranq", "syringe_blood", "syringe_monster":
			var liquid := base
			draw_rect(Rect2(18, 26, 30, 14), Color("#d7dee4"))
			draw_rect(Rect2(18, 26, 30, 14), Color("#b9c4cc"), false, 1.5)
			draw_rect(Rect2(22, 29, 14, 8), liquid)
			for i in range(4):
				draw_line(Vector2(26 + i * 5, 26), Vector2(26 + i * 5, 22), Color("#b9c4cc"), 1.0, true)
			draw_rect(Rect2(48, 29, 6, 8), Color("#9aa8b2"))
			draw_line(Vector2(54, 33), Vector2(62, 33), Color("#d7dee4"), 2.0, true)
			draw_rect(Rect2(10, 29, 8, 8), Color("#9aa8b2"))
			draw_rect(Rect2(5, 27, 6, 12), Color("#7f8c96"))
		"knife":
			draw_colored_polygon(PackedVector2Array([
				Vector2(12, 42), Vector2(36, 18), Vector2(48, 14),
				Vector2(44, 26), Vector2(20, 48)
			]), Color("#c3c9cf"))
			draw_line(Vector2(14, 44), Vector2(42, 18), Color("#eef2f4"), 1.4, true)
			draw_line(Vector2(36, 26), Vector2(50, 38), Color("#8a6a4a"), 7.0, true)
			draw_circle(Vector2(51, 40), 3.5, Color("#6e5136"))
		"rod":
			draw_line(Vector2(12, 54), Vector2(49, 12), Color("#a47d4e"), 3.0, true)
			draw_line(Vector2(49, 12), Vector2(56, 28), Color("#d7dee4"), 1.2, true)
			draw_arc(Vector2(54, 33), 5.0, -0.2, PI * 1.1, 10, Color("#d7dee4"), 1.4, true)
			draw_circle(Vector2(30, 36), 6.0, Color("#7f8c96"))
			draw_circle(Vector2(30, 36), 3.0, Color("#3f4a55"))
			draw_line(Vector2(12, 54), Vector2(20, 47), Color("#6e5136"), 4.0, true)
		"music_box":
			draw_rect(Rect2(14, 30, 36, 22), base)
			draw_rect(Rect2(14, 30, 36, 6), base.lightened(0.18))
			draw_rect(Rect2(18, 36, 28, 12), base.darkened(0.2))
			draw_circle(Vector2(32, 42), 5.0, Color("#d6b36a"))
			draw_line(Vector2(50, 38), Vector2(58, 33), Color("#9aa8b2"), 2.0, true)
			draw_line(Vector2(58, 33), Vector2(58, 44), Color("#9aa8b2"), 2.0, true)
			draw_circle(Vector2(58, 45), 2.0, Color("#9aa8b2"))
			draw_circle(Vector2(48, 17), 2.0, Color("#e8e3d4"))
			draw_line(Vector2(48, 17), Vector2(48, 26), Color("#e8e3d4"), 1.5, true)
			draw_circle(Vector2(40, 23), 2.0, Color("#e8e3d4"))
			draw_line(Vector2(40, 23), Vector2(40, 32), Color("#e8e3d4"), 1.5, true)
		"diary":
			draw_rect(Rect2(17, 12, 32, 42), base)
			draw_rect(Rect2(20, 15, 26, 36), base.lightened(0.35))
			draw_rect(Rect2(17, 12, 7, 42), base.darkened(0.25))
			draw_line(Vector2(28, 18), Vector2(28, 48), Color(base.darkened(0.4), 0.7), 1.0, true)
			draw_rect(Rect2(43, 30, 6, 10), Color("#d6b36a"))
			draw_circle(Vector2(46, 35), 1.8, base.darkened(0.4))
		"candle":
			draw_circle(Vector2(32, 20), 13.0, Color(base, 0.12))
			draw_rect(Rect2(24, 30, 16, 26), Color("#e6d8c3"))
			draw_rect(Rect2(24, 30, 6, 26), Color("#cfc0aa"))
			draw_line(Vector2(32, 30), Vector2(32, 25), Color("#5a4632"), 1.6, true)
			draw_colored_polygon(PackedVector2Array([
				Vector2(32, 12), Vector2(38, 22), Vector2(32, 28), Vector2(26, 22)
			]), Color("#e9b85f"))
			draw_circle(Vector2(32, 23), 3.0, Color("#f6e2a8"))
		_:
			draw_circle(Vector2(32, 32), 18, base)


func _ellipse_points(cx: float, cy: float, rx: float, ry: float, steps: int, start_angle: float, end_angle: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var ang := lerpf(start_angle, end_angle, t)
		pts.append(Vector2(cx + cos(ang) * rx, cy + sin(ang) * ry))
	return pts
