extends Control
## Bottom dialog card with a typewriter reveal and click-anywhere advance.

signal finished

var _lines: Array = []
var _index := 0
var _typing := false
var _tween: Tween
var _speaker: Label
var _text: Label
var _hint: Label
var _panel: PanelContainer
var _blocker: ColorRect


func _ready() -> void:
	theme = UI.theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_blocker = ColorRect.new()
	_blocker.color = Color(0.01, 0.015, 0.025, 0.22)
	_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.gui_input.connect(_on_blocker_input)
	add_child(_blocker)

	_panel = PanelContainer.new()
	_panel.theme_type_variation = "DialogPanel"
	_panel.anchor_left = 0.08
	_panel.anchor_right = 0.92
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = -274
	_panel.offset_bottom = -116
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	_speaker = UI.label("", "DialogSpeaker")
	box.add_child(_speaker)

	_text = UI.label("", "DialogText")
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_constant_override("line_spacing", 4)
	box.add_child(_text)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)

	_hint = UI.label("Clique para continuar", "Tiny")
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_hint)

	var next := UI.button("CONTINUAR", "GhostButton")
	next.custom_minimum_size = Vector2(136, 34)
	next.pressed.connect(advance)
	footer.add_child(next)


func open(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	_render()


func advance() -> void:
	if not visible:
		return
	if _typing:
		if _tween and _tween.is_valid():
			_tween.kill()
		_text.visible_ratio = 1.0
		_typing = false
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_render()


func _render() -> void:
	if _index >= _lines.size():
		_close()
		return

	var raw: Variant = _lines[_index]
	var line: Dictionary = raw if raw is Dictionary else {"text": String(raw)}
	var speaker := String(line.get("speaker", ""))
	var text := String(line.get("text", ""))

	_speaker.text = speaker
	_speaker.visible = speaker != ""
	_text.text = text
	_text.visible_ratio = 0.0
	_hint.text = "Clique para fechar" if _index >= _lines.size() - 1 else "Clique para continuar"

	if _tween and _tween.is_valid():
		_tween.kill()
	_typing = true
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, clampf(float(text.length()) * 0.012, 0.18, 0.9))
	_tween.finished.connect(func() -> void: _typing = false)


func _close() -> void:
	if not visible:
		return
	visible = false
	_typing = false
	if _tween and _tween.is_valid():
		_tween.kill()
	finished.emit()


func _on_blocker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		advance()
