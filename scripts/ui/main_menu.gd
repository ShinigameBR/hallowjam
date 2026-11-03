extends Control
## Main menu: quiet typography over a painted sea.

const MENU_BUTTON := preload("res://scripts/ui/menu_button.gd")
const HELP_PANEL := preload("res://scripts/ui/help_panel.gd")

var _content: VBoxContainer
var _buttons: Array[Button] = []
var _continue_button: Button
var _options: Control
var _options_panel: PanelContainer
var _help: Control
var _volume_slider: HSlider
var _volume_value: Label
var _fullscreen_button: Button
var _overlay: Control


func _ready() -> void:
	theme = UI.theme
	_build()
	_build_options()
	_build_help()
	_refresh_continue()
	_play_intro()
	if _buttons.size() > 0:
		_buttons[0].grab_focus()


func _build() -> void:
	# Thin vertical rule, like a margin annotation in an old book.
	var rule := ColorRect.new()
	rule.color = Color(UI.ACCENT, 0.22)
	rule.anchor_left = 0.062
	rule.anchor_top = 0.18
	rule.anchor_right = 0.062
	rule.anchor_bottom = 0.82
	rule.offset_right = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)

	var diamond := ColorRect.new()
	diamond.color = UI.ACCENT
	diamond.anchor_left = 0.062
	diamond.anchor_top = 0.18
	diamond.anchor_right = 0.062
	diamond.anchor_bottom = 0.18
	diamond.offset_left = -2
	diamond.offset_top = 18
	diamond.offset_right = 3
	diamond.offset_bottom = 23
	diamond.rotation = PI * 0.25
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(diamond)

	_content = VBoxContainer.new()
	_content.anchor_left = 0.085
	_content.anchor_top = 0.10
	_content.anchor_right = 0.56
	_content.anchor_bottom = 0.90
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 3)
	add_child(_content)

	_content.add_child(UI.label("HALLOWJAM 2026", "EyebrowMuted"))
	_content.add_child(UI.spacer(4))

	var title := UI.label("CÍRCULO", "Title")
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", UI.ACCENT)
	_content.add_child(title)

	var subtitle := UI.label("UM RITUAL PARA ESCAPAR", "Eyebrow")
	_content.add_child(subtitle)

	_content.add_child(UI.spacer(12))
	var line := ColorRect.new()
	line.color = Color(UI.ACCENT, 0.45)
	line.custom_minimum_size = Vector2(64, 1)
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(line)
	_content.add_child(UI.spacer(10))

	var tagline := UI.label("Uma cabana no meio do mar.\nUm bruxo que não está mais lá.", "BodyLarge")
	tagline.add_theme_color_override("font_color", Color(UI.TEXT, 0.72))
	tagline.add_theme_constant_override("line_spacing", 4)
	_content.add_child(tagline)

	_content.add_child(UI.spacer(22))

	_add_menu_button("NOVO JOGO", _on_new_game)
	_continue_button = _add_menu_button("CONTINUAR", _on_continue)
	_add_menu_button("COMO JOGAR", _on_help)
	_add_menu_button("OPÇÕES", _on_options)
	if not OS.has_feature("web"):
		_add_menu_button("SAIR", _on_quit)

	var footer := UI.label("Clique para escolher  ·  Enter para confirmar", "Tiny")
	footer.anchor_left = 0.085
	footer.anchor_top = 0.935
	footer.anchor_right = 0.6
	footer.anchor_bottom = 0.97
	add_child(footer)

	var version := UI.label("v0.1", "Tiny")
	version.anchor_left = 0.8
	version.anchor_top = 0.935
	version.anchor_right = 0.94
	version.anchor_bottom = 0.97
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)


func _add_menu_button(text: String, callback: Callable) -> Button:
	var b: Button = MENU_BUTTON.new()
	b.text = text
	b.pressed.connect(callback)
	_content.add_child(b)
	_buttons.append(b)
	return b


func _refresh_continue() -> void:
	if _continue_button == null:
		return
	var available := GameState.has_save()
	_continue_button.disabled = not available
	_continue_button.tooltip_text = "" if available else "Nenhum ritual em andamento."
	if available:
		_continue_button.text = "CONTINUAR"
	else:
		_continue_button.text = "CONTINUAR  ·  —"


func _play_intro() -> void:
	var art := get_node_or_null("Art")
	if art:
		art.modulate.a = 0.0
		var at := create_tween()
		at.tween_property(art, "modulate:a", 1.0, 1.4)
	var backdrop := get_node_or_null("Backdrop")
	if backdrop:
		backdrop.modulate.a = 0.0
		var bt := create_tween()
		bt.tween_property(backdrop, "modulate:a", 1.0, 1.2)
	_content.modulate.a = 0.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_content, "modulate:a", 1.0, 0.6).set_delay(0.15)
	for i in range(_buttons.size()):
		_buttons[i].modulate.a = 0.0
		var bt := create_tween()
		bt.tween_property(_buttons[i], "modulate:a", 1.0, 0.35).set_delay(0.28 + i * 0.06)


# ------------------------------------------------------------------ actions
func _on_new_game() -> void:
	GameState.start_new_game()
	SceneTransition.change_scene("res://scenes/game.tscn")


func _on_continue() -> void:
	if GameState.load_game():
		SceneTransition.change_scene("res://scenes/game.tscn")
	else:
		_refresh_continue()


func _on_help() -> void:
	_help.open()


func _on_options() -> void:
	_refresh_fullscreen_button()
	_show_overlay(_options, _options_panel)
	_volume_slider.grab_focus()


func _on_quit() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _help.visible:
			_help.close()
			get_viewport().set_input_as_handled()
		elif _options.visible:
			_hide_overlay(_options)
			get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ options overlay
func _build_options() -> void:
	_options = Control.new()
	_options.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_options.mouse_filter = Control.MOUSE_FILTER_STOP
	_options.visible = false
	add_child(_options)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_hide_overlay(_options)
	)
	_options.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options.add_child(center)

	_options_panel = PanelContainer.new()
	_options_panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(_options_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	_options_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	box.add_child(UI.label("OPÇÕES", "Eyebrow"))
	box.add_child(UI.label("Ajuste a sala ao seu gosto.", "H2"))
	box.add_child(UI.spacer(4))
	box.add_child(UI.hline(Color(1, 1, 1, 0.08), 1))
	box.add_child(UI.spacer(4))

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 14)
	box.add_child(volume_row)
	var volume_label := UI.label("Volume geral", "BodyLarge")
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(volume_label)
	_volume_value = UI.label("%d%%" % roundi(Settings.master_volume * 100.0), "Muted")
	_volume_value.custom_minimum_size = Vector2(48, 0)
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_row.add_child(_volume_value)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.01
	_volume_slider.value = Settings.master_volume
	_volume_slider.custom_minimum_size = Vector2(0, 28)
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.tooltip_text = "Arraste para ajustar o volume."
	_volume_slider.value_changed.connect(func(value: float) -> void:
		Settings.set_master_volume(value)
		_volume_value.text = "%d%%" % roundi(value * 100.0)
	)
	box.add_child(_volume_slider)

	_fullscreen_button = UI.button("", "GhostButton")
	_fullscreen_button.custom_minimum_size = Vector2(0, 42)
	_fullscreen_button.pressed.connect(_toggle_fullscreen)
	box.add_child(_fullscreen_button)

	if Settings.is_embedded():
		_fullscreen_button.disabled = true
		_fullscreen_button.tooltip_text = "Rode o projeto fora do editor ou desative 'Embed Game'."
		var note := UI.label("No editor, desative \"Embed Game\" para usar tela cheia.", "Tiny")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(note)

	_refresh_fullscreen_button()

	box.add_child(UI.spacer(6))
	box.add_child(UI.hline(Color(1, 1, 1, 0.07), 1))
	box.add_child(UI.spacer(4))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(footer)
	var back := UI.button("VOLTAR", "PrimaryButton")
	back.custom_minimum_size = Vector2(150, 42)
	back.pressed.connect(func() -> void: _hide_overlay(_options))
	footer.add_child(back)


func _build_help() -> void:
	_help = HELP_PANEL.new()
	add_child(_help)


func _show_overlay(overlay: Control, panel: PanelContainer) -> void:
	overlay.visible = true
	overlay.modulate.a = 0.0
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.98, 0.98)
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.22)


func _hide_overlay(overlay: Control) -> void:
	if not overlay.visible:
		return
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.14)
	await tw.finished
	overlay.visible = false

# ------------------------------------------------------------------ fullscreen
func _refresh_fullscreen_button() -> void:
	if _fullscreen_button == null:
		return

	var is_fullscreen := (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)

	if is_fullscreen:
		_fullscreen_button.text = "SAIR DA TELA CHEIA"
	else:
		_fullscreen_button.text = "ATIVAR TELA CHEIA"


func _toggle_fullscreen() -> void:
	if Settings.is_embedded():
		return

	var current_mode := DisplayServer.window_get_mode()

	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	_refresh_fullscreen_button()
