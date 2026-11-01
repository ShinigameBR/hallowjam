extends Control
## Every room is painted here with simple vector shapes.
## The design is deliberately flat and atmospheric: silhouettes, light and
## a few readable props, so art can be swapped in later without touching logic.

var room_id: String = "main"
var _time := 0.0
var _motes: Array[Vector3] = []
var _grain: Array[Vector3] = []
var _vignette: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for i in range(36):
		_motes.append(Vector3(rng.randf(), rng.randf_range(0.08, 0.9), rng.randf_range(0.4, 1.4)))
	for i in range(220):
		_grain.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.3, 1.0)))
	_vignette = _build_vignette()
	GameState.flags_changed.connect(queue_redraw)
	GameState.inventory_changed.connect(queue_redraw)


func set_room(id: String) -> void:
	room_id = id
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	match room_id:
		"main":
			_draw_main(w, h)
		"kitchen":
			_draw_kitchen(w, h)
		"basement":
			_draw_basement(w, h)
		"outside":
			_draw_outside(w, h)
		_:
			_draw_main(w, h)
	_draw_atmosphere(w, h)


# =================================================================== MAIN ROOM
func _draw_main(w: float, h: float) -> void:
	_draw_shell(w, h, Color("#19222f"), Color("#232d3b"), Color("#221d19"), Color("#120f0d"))

	# wall panelling
	for x in [0.17, 0.37, 0.57, 0.77]:
		_nline(x, 0.02, x, 0.56, Color(0, 0, 0, 0.16), 1.0)
	_nline(0.0, 0.12, 1.0, 0.12, Color(0, 0, 0, 0.18), 1.0)

	_draw_bookshelf(w, h)
	_draw_main_door(w, h)
	_draw_window(w, h)
	_draw_side_doors(w, h)
	_draw_mirror(w, h)
	_draw_music_table(w, h)
	_draw_wall_moss(w, h)
	_draw_mushrooms(w, h)
	_draw_floor_circle(w, h)
	_draw_safe(w, h)
	_draw_hanging_herbs(w, h)
	_draw_cracks(w, h)

	if GameState.has_flag("summoned_green"):
		_draw_green_companion(w, h)


func _draw_bookshelf(w: float, h: float) -> void:
	_nrect(0.168, 0.145, 0.202, 0.375, Color("#2a1d15"))
	_nrect(0.176, 0.153, 0.186, 0.359, Color("#15100c"))
	_nrect(0.163, 0.138, 0.212, 0.018, Color("#3a2a1e"))
	_nrect(0.163, 0.512, 0.212, 0.012, Color("#3a2a1e"))
	for i in range(3):
		var y := 0.235 + i * 0.09
		_nrect(0.176, y, 0.186, 0.008, Color("#3a2a1e"))
		_nrect(0.176, y + 0.008, 0.186, 0.005, Color(0, 0, 0, 0.35))

	# The shelf is also the strongbox clue: exactly 3 blue, 1 red,
	# 4 green and 2 yellow books. Keep these counts if you re-art the room.
	var palette := {
		"blue": Color("#405f8a"),
		"red": Color("#7a3a45"),
		"green": Color("#4e7a54"),
		"yellow": Color("#8a7436"),
	}
	var shelves := [
		["blue", "blue", "red", "yellow"],
		["blue", "green", "green", "yellow"],
		["green", "green"],
	]
	for shelf in range(3):
		var base_y := 0.225 + shelf * 0.09
		var x := 0.183
		var shelf_books: Array = shelves[shelf]
		for i in range(shelf_books.size()):
			var bw := 0.013
			var bh := 0.048 + float((i + shelf) % 3) * 0.005
			var c: Color = palette[String(shelf_books[i])]
			_nrect(x, base_y - bh, bw, bh, c)
			_nrect(x, base_y - bh, bw * 0.3, bh, Color(0, 0, 0, 0.18))
			_nline(x, base_y - bh + 0.006, x + bw, base_y - bh + 0.006, Color(0.9, 0.82, 0.6, 0.22), 0.8)
			_nrect(x, base_y - 0.014, bw, 0.014, c.darkened(0.08))
			x += bw + 0.003
	# a neutral, uncounted book leaning on the shelf
	_nrect(0.33, 0.37, 0.012, 0.05, Color("#4b4f6e"))
	_nrect(0.318, 0.4, 0.014, 0.022, Color("#5a3a5a"))

	# small skull on top
	_nellipse(0.315, 0.132, 0.012, 0.01, Color("#c9bda6"))
	_ncircle(0.315, 0.128, 0.006, Color("#c9bda6"))
	_ncircle(0.3125, 0.127, 0.0018, Color("#15100c"))
	_ncircle(0.3175, 0.127, 0.0018, Color("#15100c"))


func _draw_main_door(w: float, h: float) -> void:
	# frame and heavy door
	_nrect(0.412, 0.155, 0.176, 0.415, Color("#2b2018"))
	_nrect(0.421, 0.168, 0.158, 0.402, Color("#3b2a1d"))
	_nrect(0.428, 0.176, 0.144, 0.394, Color("#332317"))
	for i in range(4):
		_nline(0.432, 0.205 + i * 0.09, 0.568, 0.205 + i * 0.09, Color(0, 0, 0, 0.25), 1.0)
	_nrect(0.43, 0.18, 0.14, 0.012, Color("#4a3625"))
	_ncircle(0.552, 0.383, 0.008, Color("#c9a35e"))
	_ncircle(0.552, 0.383, 0.004, Color("#3a2a1e"))
	_nrect(0.444, 0.225, 0.112, 0.11, Color(0, 0, 0, 0.12))
	_nrect(0.444, 0.225, 0.112, 0.004, Color(0.7, 0.6, 0.42, 0.16))
	# cold light leaking under the door
	_ngradient(0.421, 0.56, 0.158, 0.028, Color(0.5, 0.7, 0.9, 0.12), Color(0.5, 0.7, 0.9, 0.0), 12)


func _draw_window(w: float, h: float) -> void:
	_nrect(0.598, 0.205, 0.152, 0.185, Color("#2b2018"))
	_nrect(0.606, 0.213, 0.136, 0.169, Color("#0b121c"))
	# sea view
	for i in range(14):
		var t := float(i) / 13.0
		_nrect(0.606, 0.213 + t * 0.169, 0.136, 0.013, Color("#0b121c").lerp(Color("#26374d"), 1.0 - t))
	var moon := Vector2(0.706 * w, 0.247 * h)
	draw_circle(moon, 0.011 * minf(w, h), Color("#e8dfc8"))
	draw_circle(moon, 0.016 * minf(w, h), Color(0.85, 0.8, 0.65, 0.08))
	for i in range(5):
		var y := 0.335 + i * 0.009
		var pts := PackedVector2Array()
		for j in range(9):
			var x := 0.608 + j * 0.017
			pts.append(Vector2(x * w, (y + sin(x * 40.0 + _time + i) * 0.002) * h))
		draw_polyline(pts, Color(0.6, 0.7, 0.8, 0.12), 1.0, true)
	# cross frame
	_nrect(0.671, 0.213, 0.006, 0.169, Color("#2b2018"))
	_nrect(0.606, 0.292, 0.136, 0.006, Color("#2b2018"))
	# sill and feather
	_nrect(0.59, 0.39, 0.168, 0.014, Color("#3a2a1e"))
	if not GameState.has_flag("picked_feather"):
		var p := Vector2(0.64 * w, 0.405 * h)
		draw_line(p, p + Vector2(0.028 * w, -0.016 * h), Color("#d8d4c8"), 2.0, true)
		for i in range(5):
			var t := float(i) / 4.0
			var a := p.lerp(p + Vector2(0.028 * w, -0.016 * h), t)
			draw_line(a, a + Vector2(-0.006 * w, -0.007 * h), Color(0.85, 0.83, 0.78, 0.75), 1.0, true)
	# light spill on the floor
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.606 * w, 0.404 * h), Vector2(0.742 * w, 0.404 * h),
		Vector2(0.79 * w, 0.66 * h), Vector2(0.56 * w, 0.66 * h),
	]), Color(0.4, 0.55, 0.75, 0.035))


func _draw_side_doors(w: float, h: float) -> void:
	# basement door (left)
	_nrect(0.045, 0.21, 0.108, 0.36, Color("#211812"))
	_nrect(0.053, 0.222, 0.092, 0.348, Color("#2b1e15"))
	var arch := PackedVector2Array()
	arch.append(Vector2(0.053 * w, 0.57 * h))
	arch.append(Vector2(0.053 * w, 0.285 * h))
	for i in range(13):
		var ang := PI + PI * float(i) / 12.0
		arch.append(Vector2(0.099 * w + cos(ang) * 0.046 * w, 0.285 * h + sin(ang) * 0.046 * w))
	arch.append(Vector2(0.145 * w, 0.57 * h))
	draw_colored_polygon(arch, Color("#24180f"))
	_nrect(0.057, 0.29, 0.084, 0.27, Color(0, 0, 0, 0.12))
	_ncircle(0.138, 0.405, 0.006, Color("#8a6a4a"))
	_ncircle(0.138, 0.405, 0.011, Color(0.35, 0.3, 0.25, 0.0))
	draw_arc(Vector2(0.138 * w, 0.405 * h), 0.011 * minf(w, h), 0, TAU, 18, Color("#8a6a4a"), 1.5, true)

	# kitchen door (right)
	_nrect(0.835, 0.19, 0.118, 0.38, Color("#2b2018"))
	_nrect(0.844, 0.202, 0.10, 0.368, Color("#3b2a1d"))
	for i in range(3):
		_nline(0.85, 0.24 + i * 0.1, 0.938, 0.24 + i * 0.1, Color(0, 0, 0, 0.22), 1.0)
	_ncircle(0.852, 0.39, 0.007, Color("#c9a35e"))
	# warm light under the kitchen door
	_ngradient(0.844, 0.565, 0.10, 0.03, Color(0.95, 0.65, 0.3, 0.14), Color(0.95, 0.65, 0.3, 0.0), 12)


func _draw_mirror(w: float, h: float) -> void:
	_nellipse(0.797, 0.295, 0.033, 0.075, Color("#4a3625"))
	_nellipse(0.797, 0.295, 0.026, 0.064, Color("#0d141d"))
	_nellipse(0.79, 0.285, 0.008, 0.025, Color(0.55, 0.66, 0.78, 0.12))
	_nline(0.797, 0.218, 0.797, 0.225, Color("#c9a35e"), 2.0)


func _draw_music_table(w: float, h: float) -> void:
	_nrect(0.712, 0.49, 0.132, 0.014, Color("#3a2a1e"))
	_nrect(0.718, 0.504, 0.008, 0.11, Color("#2a1d15"))
	_nrect(0.828, 0.504, 0.008, 0.11, Color("#2a1d15"))
	_nrect(0.75, 0.505, 0.055, 0.004, Color(0, 0, 0, 0.3))
	if not GameState.has_flag("picked_music_box"):
		_nrect(0.748, 0.458, 0.052, 0.032, Color("#8a6a3a"))
		_nrect(0.748, 0.458, 0.052, 0.007, Color("#b08a4e"))
		_nrect(0.756, 0.466, 0.036, 0.016, Color("#5a3f22"))
		_ncircle(0.774, 0.474, 0.006, Color("#d6b36a"))
		_nline(0.80, 0.47, 0.815, 0.462, Color("#c9bda6"), 1.5)
		_nline(0.815, 0.462, 0.815, 0.478, Color("#c9bda6"), 1.5)


func _draw_wall_moss(w: float, h: float) -> void:
	if GameState.has_flag("picked_moss"):
		_nellipse(0.765, 0.44, 0.018, 0.014, Color(0.18, 0.24, 0.18, 0.35))
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in range(13):
		var x := 0.748 + rng.randf_range(0.0, 0.046)
		var y := 0.405 + rng.randf_range(0.0, 0.06)
		_ncircle(x, y, rng.randf_range(0.005, 0.012), Color("#4f7a4a").darkened(rng.randf_range(0.0, 0.3)))
	for i in range(4):
		var x := 0.752 + rng.randf_range(0.0, 0.04)
		var y := 0.41 + rng.randf_range(0.0, 0.045)
		_ncircle(x, y, 0.0025, Color("#e8e3d4"))


func _draw_mushrooms(w: float, h: float) -> void:
	if GameState.has_flag("picked_mushroom"):
		_ncircle(0.215, 0.575, 0.004, Color("#5d4a5a"))
		return
	var caps: Array[Vector2] = [Vector2(0.202, 0.57), Vector2(0.225, 0.565), Vector2(0.245, 0.573), Vector2(0.214, 0.585)]
	for p in caps:
		var stem_h := 0.022 + (0.202 - p.x) * 0.1
		_nrect(p.x - 0.003, p.y - stem_h, 0.006, stem_h, Color("#c9bda6"))
		_nellipse(p.x, p.y - stem_h, 0.011, 0.006, Color("#8a5a7a"))
		_ncircle(p.x - 0.004, p.y - stem_h - 0.002, 0.0015, Color("#e0cfe8"))


func _draw_floor_circle(w: float, h: float) -> void:
	var cx := 0.5
	var cy := 0.735
	var rx := 0.175
	var ry := 0.115
	# rug
	_nellipse(cx, cy + 0.01, rx * 1.25, ry * 1.3, Color("#2b1519"))
	_nellipse(cx, cy + 0.01, rx * 1.2, ry * 1.24, Color("#3a1c21"))
	_nellipse(cx, cy + 0.01, rx * 1.1, ry * 1.14, Color("#2b1519"))
	# glow
	var pulse := 0.5 + 0.5 * sin(_time * 1.6)
	for i in range(5):
		_nellipse(cx, cy, rx * (1.05 + i * 0.08), ry * (1.05 + i * 0.08), Color(0.42, 0.78, 0.7, 0.014 + (4 - i) * 0.004 * (0.5 + pulse)))
	# rings
	_ellipse_line(cx, cy, rx, ry, Color(0.84, 0.7, 0.42, 0.8), 2.0)
	_ellipse_line(cx, cy, rx * 0.92, ry * 0.92, Color(0.42, 0.78, 0.7, 0.55), 1.2)
	_ellipse_line(cx, cy, rx * 0.62, ry * 0.62, Color(0.84, 0.7, 0.42, 0.35), 1.0)
	_ellipse_line(cx, cy, rx * 0.3, ry * 0.3, Color(0.42, 0.78, 0.7, 0.28), 1.0)
	# runes
	for i in range(16):
		var ang := TAU * float(i) / 16.0 + _time * 0.04
		var p := Vector2(cx + cos(ang) * rx * 0.81, cy + sin(ang) * ry * 0.81)
		var p2 := Vector2(cx + cos(ang) * rx * 0.88, cy + sin(ang) * ry * 0.88)
		_nline(p.x, p.y, p2.x, p2.y, Color(0.84, 0.7, 0.42, 0.6), 1.4)
		_ncircle(p2.x, p2.y, 0.0022, Color(0.42, 0.78, 0.7, 0.7))
	# central sigil
	for i in range(3):
		var ang := _time * 0.15 + TAU * float(i) / 3.0
		var a := Vector2(cx + cos(ang) * rx * 0.28, cy + sin(ang) * ry * 0.28)
		var b := Vector2(cx + cos(ang + TAU / 3.0) * rx * 0.28, cy + sin(ang + TAU / 3.0) * ry * 0.28)
		_nline(a.x, a.y, b.x, b.y, Color(0.84, 0.7, 0.42, 0.3), 1.0)


func _draw_safe(w: float, h: float) -> void:
	# Small iron strongbox sitting at the edge of the rug.
	_nellipse(0.28, 0.683, 0.057, 0.013, Color(0, 0, 0, 0.38))
	_nrect(0.23, 0.605, 0.10, 0.075, Color("#1c1712"))
	_nrect(0.235, 0.61, 0.09, 0.065, Color("#3a2c1e"))
	_nrect(0.235, 0.61, 0.09, 0.012, Color("#4a3826"))
	_nrect(0.235, 0.655, 0.09, 0.008, Color("#2a2016"))
	# keypad plate
	_nrect(0.285, 0.632, 0.032, 0.028, Color("#14110d"))
	for i in range(3):
		_ncircle(0.291 + i * 0.009, 0.64, 0.0018, Color("#c9a35e"))
		_ncircle(0.291 + i * 0.009, 0.65, 0.0018, Color("#8f7743"))
	# handle and hinge
	_ncircle(0.251, 0.645, 0.006, Color("#c9a35e"))
	_nrect(0.248, 0.643, 0.006, 0.013, Color("#8a6a3a"))
	_nrect(0.315, 0.612, 0.008, 0.018, Color("#6a5434"))

	if GameState.has_flag("safe_open"):
		_nrect(0.239, 0.613, 0.082, 0.018, Color("#0a0806"))
		_nline(0.235, 0.61, 0.328, 0.598, Color("#4a3826"), 3.0)
		_nline(0.239, 0.62, 0.325, 0.61, Color(0.95, 0.72, 0.35, 0.18), 1.5)
		_ncircle(0.28, 0.648, 0.034, Color(0.9, 0.7, 0.35, 0.07))


func _draw_hanging_herbs(w: float, h: float) -> void:
	for i in range(3):
		var x := 0.19 + i * 0.025
		_nline(x, 0.0, x + 0.004, 0.055, Color(0.35, 0.3, 0.22, 0.8), 1.2)
		for j in range(3):
			_nellipse(x + 0.004, 0.04 + j * 0.012, 0.006, 0.008, Color("#4f6a4a").darkened(j * 0.1))
	_nline(0.185, 0.02, 0.255, 0.02, Color("#3a2a1e"), 2.0)


func _draw_cracks(w: float, h: float) -> void:
	var c := Color(0, 0, 0, 0.22)
	_nline(0.39, 0.09, 0.402, 0.12, c, 1.0)
	_nline(0.402, 0.12, 0.395, 0.145, c, 1.0)
	_nline(0.402, 0.12, 0.415, 0.132, c, 1.0)
	_nline(0.66, 0.10, 0.67, 0.13, c, 1.0)
	_nline(0.67, 0.13, 0.66, 0.16, c, 1.0)
	# cobweb in the corner
	var web := Color(0.7, 0.7, 0.65, 0.06)
	for i in range(4):
		_nline(0.0, 0.02, 0.02 + i * 0.008, 0.08 + i * 0.01, web, 0.8)
	draw_arc(Vector2(0.0, 0.02 * h), 0.06 * minf(w, h), 0.3, 1.3, 12, web, 0.8, true)


func _draw_green_companion(w: float, h: float) -> void:
	var cx := 0.59
	var cy := 0.515
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	_ncircle(cx, cy, 0.075, Color(0.35, 0.75, 0.55, 0.035 + pulse * 0.02))
	# body and head
	_nellipse(cx, cy + 0.035, 0.03, 0.04, Color("#4e8f68"))
	_ncircle(cx, cy - 0.012, 0.026, Color("#5aa877"))
	# long arms
	_nline(cx - 0.02, cy + 0.02, cx - 0.05, cy + 0.065, Color("#4e8f68"), 3.0)
	_nline(cx + 0.02, cy + 0.02, cx + 0.05, cy + 0.06, Color("#4e8f68"), 3.0)
	# eyes
	_ncircle(cx - 0.009, cy - 0.016, 0.006, Color("#0b1410"))
	_ncircle(cx + 0.009, cy - 0.016, 0.006, Color("#0b1410"))
	_ncircle(cx - 0.008, cy - 0.018, 0.002, Color("#d9ffe8"))
	_ncircle(cx + 0.01, cy - 0.018, 0.002, Color("#d9ffe8"))


# ====================================================================== KITCHEN
func _draw_kitchen(w: float, h: float) -> void:
	_draw_shell(w, h, Color("#241f1c"), Color("#2c2520"), Color("#1d1713"), Color("#0f0b09"))

	# window over the sink
	_nrect(0.615, 0.145, 0.135, 0.16, Color("#2b2018"))
	_nrect(0.623, 0.153, 0.119, 0.144, Color("#0b121c"))
	for i in range(10):
		var t := float(i) / 9.0
		_nrect(0.623, 0.153 + t * 0.144, 0.119, 0.015, Color("#0b121c").lerp(Color("#2b3d50"), 1.0 - t))
	var moon := Vector2(0.70 * w, 0.18 * h)
	draw_circle(moon, 0.008 * minf(w, h), Color("#e8dfc8"))
	_nrect(0.682, 0.153, 0.005, 0.144, Color("#2b2018"))
	_nrect(0.623, 0.222, 0.119, 0.005, Color("#2b2018"))

	# shelves
	_nrect(0.34, 0.13, 0.225, 0.022, Color("#3a2a1e"))
	_nrect(0.34, 0.255, 0.225, 0.014, Color("#3a2a1e"))
	for i in range(7):
		var x := 0.35 + i * 0.03
		var bh := 0.04 + (i % 3) * 0.012
		_nrect(x, 0.13 - bh + 0.02, 0.018, bh, [Color("#4a5a62"), Color("#6a4d3a"), Color("#4e6a4a"), Color("#5a4a6a")][i % 4])
		if i % 2 == 0:
			_ncircle(x + 0.009, 0.148, 0.007, Color("#c9bda6"))
	_nellipse(0.40, 0.245, 0.015, 0.01, Color("#8a6a4a"))
	_nellipse(0.49, 0.242, 0.018, 0.012, Color("#5a4a3a"))

	# hanging pots
	_nline(0.58, 0.0, 0.58, 0.06, Color("#2a2a2a"), 1.0)
	_nline(0.73, 0.0, 0.73, 0.06, Color("#2a2a2a"), 1.0)
	_nline(0.58, 0.06, 0.73, 0.06, Color("#3a3a3a"), 2.0)
	for i in range(3):
		var x := 0.61 + i * 0.045
		_nline(x, 0.06, x, 0.105, Color("#2a2a2a"), 1.0)
		_nellipse(x, 0.125, 0.018, 0.016, Color("#4a4a4a"))
		_nellipse(x, 0.118, 0.018, 0.006, Color("#5a5a5a"))

	# counter
	_nrect(0.12, 0.40, 0.78, 0.022, Color("#4a3626"))
	_nrect(0.12, 0.422, 0.78, 0.13, Color("#2c2018"))
	for i in range(5):
		var x := 0.14 + i * 0.15
		_nrect(x, 0.44, 0.13, 0.095, Color("#241a13"))
		_nrect(x + 0.008, 0.448, 0.114, 0.079, Color("#2e2118"))
		_ncircle(x + 0.065, 0.487, 0.004, Color("#8a6a4a"))

	# stove
	_nrect(0.12, 0.31, 0.175, 0.09, Color("#2a2624"))
	_nrect(0.13, 0.33, 0.155, 0.07, Color("#1a1817"))
	_ncircle(0.165, 0.365, 0.012, Color("#0a0908"))
	_ncircle(0.22, 0.365, 0.012, Color("#0a0908"))
	_nellipse(0.165, 0.35, 0.022, 0.014, Color("#3a3a3a"))
	_nellipse(0.22, 0.35, 0.022, 0.014, Color("#3a3a3a"))
	# fire in the oven
	var flicker := 0.6 + 0.4 * sin(_time * 7.0) * sin(_time * 3.3)
	_nrect(0.175, 0.425, 0.075, 0.045, Color("#0d0a08"))
	_nellipse(0.212, 0.458, 0.028, 0.012, Color(0.9, 0.45, 0.18, 0.55 * flicker))
	_ncircle(0.2, 0.452, 0.008, Color(1.0, 0.65, 0.25, 0.7 * flicker))
	_ncircle(0.225, 0.455, 0.006, Color(1.0, 0.55, 0.2, 0.6 * flicker))
	_ncircle(0.212, 0.455, 0.06, Color(1.0, 0.5, 0.2, 0.035 * flicker))
	# stove pipe
	_nrect(0.235, 0.0, 0.022, 0.31, Color("#24211f"))
	_nrect(0.228, 0.0, 0.036, 0.012, Color("#2e2a28"))

	# sink
	_nrect(0.60, 0.375, 0.155, 0.045, Color("#3a3a3a"))
	_nrect(0.61, 0.383, 0.135, 0.028, Color("#151515"))
	_nellipse(0.677, 0.39, 0.06, 0.012, Color("#0a0a0a"))
	# tap
	draw_arc(Vector2(0.677 * w, 0.345 * h), 0.025 * minf(w, h), PI, TAU, 16, Color("#8a8a8a"), 2.5, true)
	_nrect(0.675, 0.32, 0.005, 0.03, Color("#8a8a8a"))
	_ncircle(0.677, 0.39, 0.002, Color(0.5, 0.65, 0.75, 0.6))
	_nline(0.677, 0.393, 0.677, 0.40 + sin(_time * 2.0) * 0.002, Color(0.5, 0.65, 0.75, 0.35), 1.0)

	# back door
	_nrect(0.035, 0.19, 0.115, 0.38, Color("#2b2018"))
	_nrect(0.044, 0.202, 0.097, 0.368, Color("#3b2a1d"))
	_ncircle(0.132, 0.39, 0.007, Color("#c9a35e"))

	# items on the counter
	if not GameState.has_flag("picked_knife"):
		_nrect(0.315, 0.365, 0.018, 0.038, Color("#3a2a1e"))
		_nline(0.322, 0.365, 0.326, 0.335, Color("#c3c9cf"), 2.0)
		_nline(0.328, 0.367, 0.332, 0.34, Color("#c3c9cf"), 2.0)
	if not GameState.has_flag("picked_potion"):
		_nellipse(0.845, 0.382, 0.014, 0.018, Color("#6a4d8a"))
		_nrect(0.841, 0.362, 0.008, 0.015, Color("#8a8a8a"))
		_ncircle(0.845, 0.38, 0.006, Color("#b58ad6"))
	if not GameState.has_flag("picked_syringe"):
		_nrect(0.775, 0.392, 0.045, 0.008, Color("#b9c4cc"))
		_nrect(0.775, 0.392, 0.02, 0.008, Color("#7fb6c9"))
		_nline(0.82, 0.396, 0.835, 0.396, Color("#b9c4cc"), 1.0)
	if not GameState.has_flag("picked_candle"):
		_nrect(0.545, 0.36, 0.016, 0.04, Color("#e6d8c3"))
		_ncircle(0.553, 0.355, 0.012, Color(0.95, 0.7, 0.3, 0.08))
		_nellipse(0.553, 0.35, 0.005, 0.01, Color("#e9b85f"))

	# warm stove light
	for i in range(4):
		_ncircle(0.21, 0.42, 0.08 + i * 0.04, Color(1.0, 0.55, 0.22, 0.012 * flicker))


# ===================================================================== BASEMENT
func _draw_basement(w: float, h: float) -> void:
	var lit := GameState.has_flag("basement_lit")
	_draw_shell(w, h, Color("#171b1d"), Color("#1d2123"), Color("#171310"), Color("#0a0807"))

	# beams
	_nrect(0.245, 0.0, 0.035, 0.58, Color("#211710"))
	_nrect(0.72, 0.0, 0.035, 0.58, Color("#211710"))
	_nrect(0.0, 0.18, 1.0, 0.025, Color("#1b120c"))
	_nline(0.0, 0.185, 1.0, 0.185, Color(0, 0, 0, 0.35), 1.0)

	# door and warm light from above
	_nrect(0.055, 0.18, 0.115, 0.40, Color("#211812"))
	_nrect(0.064, 0.192, 0.097, 0.388, Color("#2b1e15"))
	_ncircle(0.148, 0.39, 0.006, Color("#8a6a4a"))
	_ngradient(0.055, 0.555, 0.115, 0.04, Color(0.95, 0.65, 0.3, 0.16), Color(0.95, 0.65, 0.3, 0.0), 10)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.064 * w, 0.58 * h), Vector2(0.161 * w, 0.58 * h),
		Vector2(0.24 * w, 0.8 * h), Vector2(0.0, 0.8 * h),
	]), Color(0.9, 0.6, 0.28, 0.035))

	# crates
	_nrect(0.29, 0.445, 0.13, 0.115, Color("#33251a"))
	_nrect(0.295, 0.45, 0.12, 0.105, Color("#3d2d20"))
	_nline(0.295, 0.45, 0.415, 0.555, Color("#2a1d15"), 1.5)
	_nline(0.415, 0.45, 0.295, 0.555, Color("#2a1d15"), 1.5)
	_nrect(0.34, 0.51, 0.12, 0.08, Color("#2b1f16"))
	_nline(0.34, 0.55, 0.46, 0.55, Color("#3d2d20"), 2.0)

	# barrel
	_nrect(0.83, 0.40, 0.09, 0.18, Color("#3a2a1e"))
	_nrect(0.825, 0.41, 0.10, 0.012, Color("#5a4a3a"))
	_nrect(0.825, 0.55, 0.10, 0.012, Color("#5a4a3a"))
	_nellipse(0.875, 0.40, 0.05, 0.014, Color("#2a1d15"))
	_nellipse(0.875, 0.402, 0.038, 0.009, Color("#6a8a4e"))
	_ncircle(0.875, 0.402, 0.03, Color(0.5, 0.8, 0.35, 0.12))
	_ncircle(0.862, 0.4, 0.004, Color(0.7, 1.0, 0.45, 0.5))
	_ncircle(0.888, 0.404, 0.003, Color(0.7, 1.0, 0.45, 0.4))

	# fishing rod leaning
	if not GameState.has_flag("picked_rod"):
		_nline(0.205, 0.58, 0.255, 0.30, Color("#8a6a4a"), 2.5)
		_nline(0.255, 0.30, 0.27, 0.36, Color("#c9bda6"), 1.0)
		_ncircle(0.225, 0.46, 0.007, Color("#5a5a5a"))

	# cage
	var cage_x := 0.56
	var cage_y := 0.30
	var cage_w := 0.22
	var cage_h := 0.31
	_nrect(cage_x - 0.008, cage_y - 0.01, cage_w + 0.016, 0.012, Color("#2a2a2a"))
	_nrect(cage_x - 0.008, cage_y + cage_h, cage_w + 0.016, 0.012, Color("#2a2a2a"))
	for i in range(7):
		var x := cage_x + i * (cage_w / 6.0)
		_nline(x, cage_y, x, cage_y + cage_h, Color(0.5, 0.5, 0.48, 0.8), 1.6)
	for i in range(2):
		var y := cage_y + 0.08 + i * 0.1
		_nline(cage_x, y, cage_x + cage_w, y, Color(0.5, 0.5, 0.48, 0.55), 1.2)
	# creature inside
	var sleepy := GameState.has_flag("creature_tranquilized") or GameState.has_flag("creature_calmed")
	var body_y := cage_y + 0.19 if not sleepy else cage_y + 0.24
	_nellipse(cage_x + 0.11, body_y, 0.06, 0.07, Color("#24211d"))
	_ncircle(cage_x + 0.11, body_y - 0.055, 0.038, Color("#2c2823"))
	_ncircle(cage_x + 0.095, body_y - 0.06, 0.006, Color("#d6b36a") if not sleepy else Color("#5a5040"))
	_ncircle(cage_x + 0.125, body_y - 0.06, 0.006, Color("#d6b36a") if not sleepy else Color("#5a5040"))
	_nline(cage_x + 0.08, body_y + 0.03, cage_x + 0.055, body_y + 0.08, Color("#24211d"), 4.0)
	_nline(cage_x + 0.14, body_y + 0.03, cage_x + 0.165, body_y + 0.08, Color("#24211d"), 4.0)
	if GameState.has_flag("meat_taken"):
		_nellipse(cage_x + 0.11, cage_y + 0.28, 0.045, 0.008, Color(0.35, 0.08, 0.09, 0.55))
	# padlock
	_nrect(cage_x + 0.095, cage_y + 0.02, 0.03, 0.04, Color("#4a4a4a"))
	draw_arc(Vector2((cage_x + 0.11) * w, (cage_y + 0.02) * h), 0.012 * minf(w, h), PI, TAU, 12, Color("#5a5a5a"), 2.0, true)

	# hanging lamp (only visible when lit)
	if lit:
		_nline(0.5, 0.0, 0.5, 0.16, Color("#2a2a2a"), 1.5)
		_nellipse(0.5, 0.19, 0.03, 0.018, Color("#3a3a3a"))
		_ncircle(0.5, 0.195, 0.012, Color("#e9b85f"))
		var pulse := 0.5 + 0.5 * sin(_time * 2.2)
		for i in range(5):
			_ncircle(0.5, 0.25, 0.10 + i * 0.06, Color(1.0, 0.65, 0.3, 0.015 + pulse * 0.006))

	# cobwebs
	var web := Color(0.7, 0.7, 0.65, 0.06)
	for i in range(4):
		_nline(0.99, 0.02, 0.96 - i * 0.01, 0.08 + i * 0.01, web, 0.8)

	if not lit:
		# almost total darkness, with just enough silhouette to be curious
		draw_rect(Rect2(0, 0, w, h), Color(0.005, 0.008, 0.012, 0.86))
		_nline(0.56, 0.3, 0.56, 0.61, Color(0.35, 0.35, 0.33, 0.14), 1.2)
		_nline(0.78, 0.3, 0.78, 0.61, Color(0.35, 0.35, 0.33, 0.14), 1.2)
		_nellipse(0.875, 0.402, 0.03, 0.008, Color(0.4, 0.7, 0.3, 0.12))
		_ncircle(0.61, 0.42, 0.006, Color(0.8, 0.65, 0.3, 0.25))
		_ncircle(0.66, 0.42, 0.006, Color(0.8, 0.65, 0.3, 0.25))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.055 * w, 0.58 * h), Vector2(0.17 * w, 0.58 * h),
			Vector2(0.25 * w, 0.82 * h), Vector2(0.0, 0.82 * h),
		]), Color(0.9, 0.6, 0.28, 0.05))


# ====================================================================== OUTSIDE
func _draw_outside(w: float, h: float) -> void:
	var horizon := h * 0.56
	# sky
	for i in range(34):
		var t := float(i) / 33.0
		var c := Color("#0a1120").lerp(Color("#2b3a52"), pow(t, 1.4))
		draw_rect(Rect2(0, horizon * t, w, horizon / 33.0 + 1.0), c)
	# clouds
	for i in range(5):
		var cx := fposmod(w * (0.05 + i * 0.22) + _time * (2.0 + i * 0.6), w + w * 0.3) - w * 0.15
		var cy := h * (0.12 + i * 0.06)
		_nellipse(cx / w, cy / h, 0.14, 0.02, Color(0.1, 0.14, 0.2, 0.35))
	# moon behind clouds
	var moon := Vector2(0.36 * w, 0.17 * h)
	draw_circle(moon, 0.035 * minf(w, h), Color(0.9, 0.86, 0.72, 0.9))
	draw_circle(moon, 0.06 * minf(w, h), Color(0.9, 0.86, 0.72, 0.06))
	# sea
	for i in range(24):
		var t := float(i) / 23.0
		draw_rect(Rect2(0, horizon + (h - horizon) * t, w, (h - horizon) / 23.0 + 1.0), Color("#0c1720").lerp(Color("#04080c"), pow(t, 0.6)))
	# waves
	for i in range(14):
		var t := float(i) / 13.0
		var y := horizon + pow(t, 1.4) * (h - horizon) * 0.85
		var pts := PackedVector2Array()
		for j in range(33):
			var x := w * float(j) / 32.0
			pts.append(Vector2(x, y + sin(x * 0.008 + _time * 0.9 + i) * (1.0 + t * 3.0)))
		draw_polyline(pts, Color(0.55, 0.65, 0.72, 0.03 + t * 0.03), 1.0, true)
	# moon reflection
	for i in range(18):
		var t := float(i) / 17.0
		var y := horizon + t * (h - horizon) * 0.7
		var spread := w * (0.008 + t * 0.03)
		var shimmer := 0.5 + 0.5 * sin(_time * 1.2 + i)
		draw_line(Vector2(moon.x - spread * shimmer, y), Vector2(moon.x + spread * shimmer, y), Color(0.85, 0.8, 0.66, (1.0 - t) * 0.14), 1.5, true)

	# cabin wall on the left
	_nrect(0.0, 0.06, 0.245, 0.64, Color("#1b1713"))
	for i in range(5):
		_nline(0.0, 0.12 + i * 0.12, 0.245, 0.12 + i * 0.12, Color(0, 0, 0, 0.25), 1.0)
	_nrect(0.0, 0.04, 0.26, 0.03, Color("#120f0c"))
	_nrect(0.035, 0.28, 0.105, 0.34, Color("#2b2018"))
	_nrect(0.043, 0.29, 0.089, 0.33, Color("#3a2a1e"))
	_ncircle(0.123, 0.45, 0.006, Color("#c9a35e"))
	# lit cabin window
	_nrect(0.16, 0.29, 0.06, 0.10, Color("#2b2018"))
	_nrect(0.166, 0.296, 0.048, 0.088, Color(0.9, 0.68, 0.35, 0.75))
	_nrect(0.166, 0.296, 0.048, 0.004, Color(0.5, 0.35, 0.16))
	_nrect(0.188, 0.296, 0.004, 0.088, Color("#2b2018"))
	_nrect(0.166, 0.337, 0.048, 0.004, Color("#2b2018"))

	# dock
	var dock_top := 0.66
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.24 * w, dock_top * h), Vector2(1.0 * w, 0.60 * h),
		Vector2(1.0 * w, 0.90 * h), Vector2(0.24 * w, 0.99 * h),
	]), Color("#1c1712"))
	for i in range(7):
		var t := float(i) / 6.0
		var y := lerpf(dock_top, 0.99, pow(t, 1.2))
		draw_line(Vector2(0.24 * w, y * h), Vector2(w, lerpf(0.60, 0.90, t) * h), Color(0, 0, 0, 0.35), 1.2)
	for i in range(6):
		var x := 0.28 + i * 0.13
		draw_line(Vector2(x * w, dock_top * h), Vector2((x - 0.02) * w, 0.99 * h), Color(0, 0, 0, 0.25), 1.0)
	# posts
	for x in [0.26, 0.52, 0.79]:
		_nrect(x, 0.60, 0.012, 0.12, Color("#0f0b08"))
		_ncircle(x + 0.006, 0.60, 0.008, Color("#0f0b08"))

	# mooring post and rope at the end
	_nrect(0.50, 0.50, 0.016, 0.18, Color("#100c08"))
	_ncircle(0.508, 0.50, 0.012, Color("#100c08"))
	draw_arc(Vector2(0.508 * w, 0.63 * h), 0.035 * minf(w, h), -0.4, 1.6, 14, Color(0.45, 0.4, 0.3, 0.45), 2.0, true)

	# rocks
	_npoly([Vector2(0.70, 0.78), Vector2(0.73, 0.69), Vector2(0.80, 0.66), Vector2(0.86, 0.72), Vector2(0.84, 0.80), Vector2(0.76, 0.82)], Color("#1d2022"))
	_npoly([Vector2(0.73, 0.69), Vector2(0.80, 0.66), Vector2(0.81, 0.73), Vector2(0.75, 0.75)], Color("#2a2e30"))
	_npoly([Vector2(0.84, 0.76), Vector2(0.89, 0.71), Vector2(0.93, 0.77), Vector2(0.88, 0.82)], Color("#171a1c"))

	# algae, shell, bucket
	if not GameState.has_flag("picked_algae"):
		for i in range(9):
			var x := 0.22 + (i % 3) * 0.018
			var y := 0.72 + (i / 3) * 0.015
			_nline(x, y, x + 0.012, y + 0.06 + (i % 2) * 0.02, Color("#3f7a5a").darkened((i % 3) * 0.08), 3.0)
	if not GameState.has_flag("picked_shell"):
		_nellipse(0.62, 0.79, 0.018, 0.014, Color("#c9b9a0"))
		_nline(0.62, 0.803, 0.62, 0.78, Color("#8a7a62"), 1.0)
	if not GameState.has_flag("picked_stone"):
		_npoly([Vector2(0.78, 0.80), Vector2(0.79, 0.765), Vector2(0.82, 0.755), Vector2(0.84, 0.78), Vector2(0.825, 0.80)], Color("#6d7074"))
	# bucket
	_nrect(0.855, 0.755, 0.045, 0.055, Color("#3a3a3a"))
	_nellipse(0.8775, 0.755, 0.023, 0.007, Color("#2a2a2a"))
	draw_arc(Vector2(0.8775 * w, 0.755 * h), 0.024 * minf(w, h), PI, TAU, 12, Color("#5a5a5a"), 1.5, true)

	# rain
	for i in range(50):
		var x := fposmod(i * 0.137 * w + _time * 9.0, w)
		var y := fposmod(i * 0.091 * h + _time * 180.0, h)
		draw_line(Vector2(x, y), Vector2(x - 3, y + 14), Color(0.7, 0.78, 0.85, 0.05), 1.0, true)

	# summoned companion waiting at the end of the dock
	if GameState.has_flag("summoned_green"):
		var cx := 0.56
		var cy := 0.56
		var pulse := 0.5 + 0.5 * sin(_time * 2.0)
		_ncircle(cx, cy, 0.09, Color(0.35, 0.75, 0.55, 0.04 + pulse * 0.02))
		_nellipse(cx, cy + 0.04, 0.035, 0.045, Color("#4e8f68"))
		_ncircle(cx, cy - 0.012, 0.03, Color("#5aa877"))
		_nline(cx - 0.02, cy + 0.02, cx - 0.055, cy + 0.07, Color("#4e8f68"), 3.0)
		_nline(cx + 0.02, cy + 0.02, cx + 0.055, cy + 0.065, Color("#4e8f68"), 3.0)
		_ncircle(cx - 0.01, cy - 0.017, 0.006, Color("#0b1410"))
		_ncircle(cx + 0.01, cy - 0.017, 0.006, Color("#0b1410"))


# =================================================================== SHARED
func _draw_shell(w: float, h: float, wall_top: Color, wall_bottom: Color, floor_top: Color, floor_bottom: Color) -> void:
	_ngradient(0.0, 0.0, 1.0, 0.58, wall_top, wall_bottom, 28)
	_ngradient(0.0, 0.58, 1.0, 0.42, floor_top, floor_bottom, 18)
	_nrect(0.0, 0.555, 1.0, 0.02, Color(0, 0, 0, 0.35))
	_nrect(0.0, 0.575, 1.0, 0.008, Color(0.75, 0.62, 0.45, 0.08))
	# floorboards
	for i in range(7):
		var y := 0.60 + pow(float(i) / 6.0, 1.4) * 0.4
		_nline(0.0, y, 1.0, y, Color(0, 0, 0, 0.25), 1.0)
	for i in range(9):
		var x_bottom := -0.5 + i * 0.25
		_nline(0.5, 0.58, x_bottom, 1.0, Color(0, 0, 0, 0.18), 1.0)
	# soft shadow at ceiling
	_ngradient(0.0, 0.0, 1.0, 0.12, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.0), 12)


func _draw_atmosphere(w: float, h: float) -> void:
	# dust motes
	var alpha := 0.0
	if room_id != "basement" or GameState.has_flag("basement_lit"):
		alpha = 0.16
	for mote in _motes:
		var x := mote.x * w + sin(_time * 0.3 + mote.y * 20.0) * 10.0
		var y := fposmod(mote.y * h - _time * 4.0 * mote.z, h)
		var a := alpha * (0.25 + 0.75 * absf(sin(_time * 0.7 + mote.x * 30.0)))
		draw_circle(Vector2(x, y), mote.z * 0.7, Color(0.85, 0.75, 0.5, a * 0.22))
	# film grain
	for g in _grain:
		draw_rect(Rect2(g.x * w, g.y * h, 1.0, 1.0), Color(1, 1, 1, 0.012 * g.z))
	# vignette
	draw_texture_rect(_vignette, Rect2(0, 0, w, h), false, Color(1, 1, 1, 1))


func _build_vignette() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	g.colors = PackedColorArray([
		Color(0, 0, 0, 0),
		Color(0, 0, 0, 0.04),
		Color(0, 0, 0, 0.66),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 512
	tex.height = 512
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	return tex


# ---------------------------------------------------------------- primitives
func _nrect(x: float, y: float, rw: float, rh: float, color: Color) -> void:
	draw_rect(Rect2(x * size.x, y * size.y, rw * size.x, rh * size.y), color)


func _nline(x1: float, y1: float, x2: float, y2: float, color: Color, width: float = 1.0) -> void:
	draw_line(Vector2(x1 * size.x, y1 * size.y), Vector2(x2 * size.x, y2 * size.y), color, width, true)


func _ncircle(cx: float, cy: float, radius: float, color: Color) -> void:
	draw_circle(Vector2(cx * size.x, cy * size.y), radius * minf(size.x, size.y), color)


func _nellipse(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	draw_colored_polygon(_ellipse_points(cx * size.x, cy * size.y, rx * size.x, ry * size.y), color)


func _npoly(points: Array, color: Color) -> void:
	var pts := PackedVector2Array()
	for p in points:
		pts.append(Vector2(p.x * size.x, p.y * size.y))
	draw_colored_polygon(pts, color)


func _ngradient(x: float, y: float, rw: float, rh: float, c1: Color, c2: Color, steps: int = 20) -> void:
	for i in range(steps):
		var t := float(i) / float(maxi(steps - 1, 1))
		draw_rect(Rect2(
			x * size.x,
			(y + rh * t) * size.y,
			rw * size.x,
			rh / float(steps) * size.y + 1.0
		), c1.lerp(c2, t))


func _ellipse_line(cx: float, cy: float, rx: float, ry: float, color: Color, width: float) -> void:
	var pts := _ellipse_points(cx * size.x, cy * size.y, rx * size.x, ry * size.y)
	pts.append(pts[0])
	draw_polyline(pts, color, width, true)


func _ellipse_points(cx: float, cy: float, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(40):
		var ang := TAU * float(i) / 40.0
		pts.append(Vector2(cx + cos(ang) * rx, cy + sin(ang) * ry))
	return pts
