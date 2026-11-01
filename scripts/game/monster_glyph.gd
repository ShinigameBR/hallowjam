extends Control
## Stylised creature portrait used by the book, the summon result and the ending.

var monster_id: String = "verde"
var _time := 0.0


func setup(id: String) -> void:
	monster_id = id
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var data := ItemDB.monster(monster_id)
	var color: Color = data.get("color", UI.MUTED)
	var s := minf(size.x, size.y)
	if s <= 0.0:
		return
	var origin := (size - Vector2(s, s)) * 0.5
	draw_set_transform(origin, 0.0, Vector2(s / 256.0, s / 256.0))
	var pulse := 0.5 + sin(_time * 1.4) * 0.5
	draw_circle(Vector2(128, 128), 92.0 + pulse * 5.0, Color(color, 0.055))
	draw_circle(Vector2(128, 128), 68.0 + pulse * 3.0, Color(color, 0.06))

	match monster_id:
		"verde": _draw_verde(color)
		"azul": _draw_azul(color)
		"vermelho": _draw_vermelho(color)
		"carmesim": _draw_carmesim(color)
		"roxo": _draw_roxo(color)
		"branco": _draw_branco(color)
		_: _draw_none(color)


func _draw_verde(c: Color) -> void:
	# long limbs, round head, webbed hands
	draw_line(Vector2(100, 178), Vector2(68, 214), c.darkened(0.2), 10.0, true)
	draw_line(Vector2(156, 178), Vector2(190, 210), c.darkened(0.2), 10.0, true)
	draw_line(Vector2(92, 150), Vector2(52, 168), c.darkened(0.12), 8.0, true)
	draw_line(Vector2(164, 150), Vector2(204, 162), c.darkened(0.12), 8.0, true)
	for p in [Vector2(64, 216), Vector2(190, 212), Vector2(50, 170), Vector2(206, 164)]:
		draw_circle(p, 8.0, c.darkened(0.15))
		draw_line(p, p + Vector2(0, 12), c.darkened(0.2), 3.0, true)
	draw_colored_polygon(_ellipse(128, 156, 52, 38), c)
	draw_circle(Vector2(128, 102), 36.0, c.lightened(0.05))
	draw_colored_polygon(PackedVector2Array([
		Vector2(96, 78), Vector2(82, 56), Vector2(112, 70)
	]), c.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([
		Vector2(160, 78), Vector2(176, 54), Vector2(146, 70)
	]), c.darkened(0.1))
	draw_circle(Vector2(114, 100), 11.0, Color("#0b1410"))
	draw_circle(Vector2(144, 100), 11.0, Color("#0b1410"))
	draw_circle(Vector2(116, 97), 4.0, Color("#f2efe3"))
	draw_circle(Vector2(146, 97), 4.0, Color("#f2efe3"))
	draw_arc(Vector2(128, 118), 14, 0.25, PI - 0.25, 12, c.darkened(0.35), 3.0, true)
	draw_circle(Vector2(102, 148), 4.0, Color(c.lightened(0.25), 0.6))
	draw_circle(Vector2(148, 164), 5.0, Color(c.lightened(0.25), 0.5))


func _draw_azul(c: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(128, 50), Vector2(104, 78), Vector2(128, 92), Vector2(152, 78)
	]), c.darkened(0.1))
	draw_colored_polygon(_ellipse(128, 150, 54, 66), c)
	draw_colored_polygon(PackedVector2Array([
		Vector2(74, 140), Vector2(34, 116), Vector2(42, 154), Vector2(30, 180), Vector2(76, 168)
	]), c.darkened(0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(182, 140), Vector2(222, 116), Vector2(214, 154), Vector2(226, 180), Vector2(180, 168)
	]), c.darkened(0.16))
	draw_line(Vector2(108, 208), Vector2(92, 236), c.darkened(0.25), 9.0, true)
	draw_line(Vector2(148, 208), Vector2(164, 236), c.darkened(0.25), 9.0, true)
	for p in [Vector2(88, 238), Vector2(168, 238)]:
		draw_line(p, p + Vector2(-10, 8), c.lightened(0.2), 2.5, true)
		draw_line(p, p + Vector2(0, 10), c.lightened(0.2), 2.5, true)
		draw_line(p, p + Vector2(10, 8), c.lightened(0.2), 2.5, true)
	# blind eyes
	draw_line(Vector2(106, 108), Vector2(122, 108), Color("#0a1118"), 4.0, true)
	draw_line(Vector2(134, 108), Vector2(150, 108), Color("#0a1118"), 4.0, true)
	draw_arc(Vector2(128, 128), 20, 0.4, PI - 0.4, 12, c.darkened(0.4), 3.0, true)
	for i in range(3):
		draw_line(Vector2(84 + i * 6, 138 + i * 12), Vector2(100 + i * 6, 132 + i * 12), Color(c.lightened(0.2), 0.5), 2.0, true)
		draw_line(Vector2(172 - i * 6, 138 + i * 12), Vector2(156 - i * 6, 132 + i * 12), Color(c.lightened(0.2), 0.5), 2.0, true)


func _draw_vermelho(c: Color) -> void:
	draw_colored_polygon(_ellipse(128, 170, 86, 46), c.darkened(0.2))
	draw_colored_polygon(_ellipse(128, 150, 76, 48), c)
	draw_colored_polygon(_ellipse(128, 130, 60, 32), c.lightened(0.08))
	for i in range(4):
		var x := 72.0 + i * 38.0
		draw_line(Vector2(x, 184), Vector2(x - 8, 220), c.darkened(0.3), 12.0, true)
		draw_circle(Vector2(x - 8, 222), 8.0, c.darkened(0.35))
	draw_circle(Vector2(128, 98), 26.0, c.lightened(0.05))
	draw_circle(Vector2(118, 96), 4.0, Color("#140c0c"))
	draw_circle(Vector2(138, 96), 4.0, Color("#140c0c"))
	draw_arc(Vector2(128, 108), 10, 0.2, PI - 0.2, 8, c.darkened(0.4), 2.0, true)
	for i in range(5):
		draw_arc(Vector2(128, 150), 24.0 + i * 11.0, PI * 0.05, PI * 0.95, 14, Color(c.darkened(0.25), 0.5), 1.5, true)


func _draw_carmesim(c: Color) -> void:
	var flap := sin(_time * 8.0) * 12.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(104, 130), Vector2(42, 92 + flap), Vector2(56, 148), Vector2(28, 176), Vector2(100, 166)
	]), Color(c, 0.75))
	draw_colored_polygon(PackedVector2Array([
		Vector2(152, 130), Vector2(214, 92 - flap), Vector2(200, 148), Vector2(228, 176), Vector2(156, 166)
	]), Color(c, 0.75))
	draw_colored_polygon(_ellipse(128, 152, 30, 36), c)
	draw_circle(Vector2(128, 106), 22.0, c.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(128, 84), Vector2(120, 66), Vector2(132, 74), Vector2(136, 62), Vector2(140, 78)
	]), c.darkened(0.2))
	draw_circle(Vector2(120, 104), 4.0, Color("#170b0e"))
	draw_circle(Vector2(136, 104), 4.0, Color("#170b0e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(128, 112), Vector2(121, 120), Vector2(135, 120)
	]), Color("#d6b36a"))
	draw_line(Vector2(110, 184), Vector2(104, 204), c.darkened(0.3), 3.0, true)
	draw_line(Vector2(146, 184), Vector2(152, 204), c.darkened(0.3), 3.0, true)
	draw_arc(Vector2(128, 152), 20, 0.3, PI - 0.3, 10, Color(c.lightened(0.2), 0.45), 1.5, true)


func _draw_roxo(c: Color) -> void:
	draw_colored_polygon(_ellipse(128, 170, 62, 42), c)
	draw_colored_polygon(_ellipse(128, 136, 48, 38), c.lightened(0.05))
	draw_circle(Vector2(104, 124), 14.0, c)
	draw_circle(Vector2(152, 124), 14.0, c)
	draw_circle(Vector2(104, 124), 7.0, Color("#130d1c"))
	draw_circle(Vector2(152, 124), 7.0, Color("#130d1c"))
	draw_circle(Vector2(106, 122), 2.5, Color("#efe6ff"))
	draw_circle(Vector2(154, 122), 2.5, Color("#efe6ff"))
	draw_arc(Vector2(128, 146), 16, 0.2, PI - 0.2, 10, Color("#1a1024"), 3.0, true)
	for p in [Vector2(92, 158), Vector2(160, 150), Vector2(120, 178), Vector2(146, 184)]:
		draw_circle(p, 5.0, Color(c.lightened(0.2), 0.55))
	for i in range(4):
		var x := 80.0 + i * 32.0
		var y := 200.0 + sin(_time * 2.0 + i) * 4.0
		draw_circle(Vector2(x, y), 3.5, Color(c, 0.8))
	draw_line(Vector2(90, 194), Vector2(70, 214), c.darkened(0.25), 7.0, true)
	draw_line(Vector2(166, 194), Vector2(186, 214), c.darkened(0.25), 7.0, true)


func _draw_branco(c: Color) -> void:
	var pulse := 0.5 + sin(_time * 1.6) * 0.5
	draw_circle(Vector2(128, 128), 62.0 + pulse * 6.0, Color(c, 0.12))
	draw_circle(Vector2(128, 128), 44.0, Color(c, 0.9))
	draw_circle(Vector2(128, 128), 30.0, Color("#fffdf5"))
	for i in range(8):
		var ang := TAU * float(i) / 8.0 + _time * 0.2
		var a := Vector2(128, 128) + Vector2(cos(ang), sin(ang)) * (56.0 + pulse * 6.0)
		var b := Vector2(128, 128) + Vector2(cos(ang), sin(ang)) * 82.0
		draw_line(a, b, Color(c, 0.25), 2.0, true)
	draw_circle(Vector2(116, 124), 4.0, Color("#2a2a24"))
	draw_circle(Vector2(140, 124), 4.0, Color("#2a2a24"))
	draw_arc(Vector2(128, 138), 9, 0.2, PI - 0.2, 8, Color("#8a8065"), 2.0, true)


func _draw_none(c: Color) -> void:
	for i in range(4):
		var pts := PackedVector2Array()
		for j in range(14):
			var t := float(j) / 13.0
			var x := 82.0 + i * 22.0 + sin(t * 5.0 + _time + i) * 10.0
			var y := 190.0 - t * 120.0
			pts.append(Vector2(x, y))
		draw_polyline(pts, Color(c, 0.35 - i * 0.05), 8.0 - i, true)
	draw_circle(Vector2(128, 170), 30.0, Color(c, 0.08))


func _ellipse(cx: float, cy: float, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(28):
		var ang := TAU * float(i) / 28.0
		pts.append(Vector2(cx + cos(ang) * rx, cy + sin(ang) * ry))
	return pts
