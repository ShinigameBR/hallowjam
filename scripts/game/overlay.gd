extends Control
## Shared shell for every full-screen panel: dimmed backdrop, centred card,
## a scroll-safe body container and the open/close animation.

signal closed

var panel: PanelContainer
var body: VBoxContainer

var _dim: ColorRect
var _center: CenterContainer
var _closing := false


func _ready() -> void:
	theme = UI.theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0.015, 0.022, 0.035, 0.84)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)

	panel = PanelContainer.new()
	_center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)

	_build()


## Override in subclasses.
func _build() -> void:
	pass


## Called every time the panel becomes visible.
func _on_open() -> void:
	pass


func open() -> void:
	if visible:
		return
	_closing = false
	visible = true
	modulate.a = 0.0
	_on_open()
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.985, 0.985)
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22)


func close() -> void:
	if not visible or _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	await tw.finished
	visible = false
	_closing = false
	closed.emit()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close()


# --------------------------------------------------------------- small helpers
func _add_header(eyebrow: String, title: String, subtitle: String = "") -> void:
	body.add_child(UI.label(eyebrow, "Eyebrow"))
	body.add_child(UI.label(title, "H1"))
	if subtitle != "":
		var sub := UI.label(subtitle, "Muted")
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(sub)
	body.add_child(UI.spacer(4))
	body.add_child(UI.hline(Color(UI.ACCENT, 0.24), 1))
	body.add_child(UI.spacer(4))


func _add_footer(buttons: Array) -> void:
	body.add_child(UI.spacer(8))
	body.add_child(UI.hline(Color(1, 1, 1, 0.07), 1))
	body.add_child(UI.spacer(6))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)
	for b in buttons:
		row.add_child(b)
