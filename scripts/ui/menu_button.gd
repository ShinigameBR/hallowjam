extends Button
## A quiet editorial menu row: a thin gold mark on hover and a sliding arrow.

var _accent: ColorRect
var _arrow: Label
var _hovered := false


func _ready() -> void:
	theme_type_variation = "NavButton"
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(300, 48)
	clip_contents = false

	_accent = ColorRect.new()
	_accent.color = UI.ACCENT
	_accent.size = Vector2(2, 22)
	_accent.modulate.a = 0.0
	_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_accent)

	_arrow = Label.new()
	_arrow.text = "→"
	_arrow.add_theme_font_override("font", UI.font_body)
	_arrow.add_theme_font_size_override("font_size", 18)
	_arrow.add_theme_color_override("font_color", UI.ACCENT)
	_arrow.modulate.a = 0.0
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arrow)

	resized.connect(_layout)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(_set_hovered.bind(true))
	focus_exited.connect(_set_hovered.bind(false))
	_layout()


func _layout() -> void:
	_accent.position = Vector2(0, (size.y - _accent.size.y) * 0.5)
	_arrow.size = Vector2(28, 28)
	_arrow.position = Vector2(size.x - 38, (size.y - 28) * 0.5)


func _set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_accent, "modulate:a", 1.0 if value else 0.0, 0.18)
	tw.tween_property(_arrow, "modulate:a", 1.0 if value else 0.0, 0.18)
	tw.tween_property(_arrow, "position:x", size.x - 30 if value else size.x - 38, 0.18)
