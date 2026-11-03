extends Control
## Atmosphere layer for the main menu. The environment art lives in the `Art`
## TextureRect; this node only adds grain, rain, drifting motes and the dim
## scrim that keeps the menu typography readable.

var _time := 0.0
var _motes: Array[Vector3] = []
var _rain: Array[Vector3] = []
var _vignette: GradientTexture2D
var _scrim: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261031
	for i in range(26):
		_motes.append(Vector3(rng.randf(), rng.randf_range(0.35, 0.95), rng.randf_range(0.5, 1.6)))
	for i in range(70):
		_rain.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.4, 1.2)))
	_vignette = _build_vignette()
	_scrim = _build_scrim()


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

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

	# readability scrim and vignette
	draw_texture_rect(_scrim, Rect2(0, 0, w, h), false, Color(1, 1, 1, 1))
	draw_texture_rect(_vignette, Rect2(0, 0, w, h), false, Color(1, 1, 1, 1))


func _build_scrim() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 0.78])
	g.colors = PackedColorArray([
		Color(0.02, 0.03, 0.05, 0.82),
		Color(0.02, 0.03, 0.05, 0.46),
		Color(0.02, 0.03, 0.05, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 8
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(1.0, 0.0)
	return tex


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
