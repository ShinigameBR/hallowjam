extends "res://scripts/game/overlay.gd"
## In-game pause card. The tree is not paused; the dim layer simply blocks
## gameplay input so the ambience keeps breathing behind the panel.

signal resume_requested
signal menu_requested

const HELP_PANEL := preload("res://scripts/ui/help_panel.gd")

var _help: Control
var _stats: Label
var _volume_value: Label


func _build() -> void:
	panel.custom_minimum_size = Vector2(540, 0)

	_add_header("PAUSA", "Respire.", "O ritual espera. Nada aqui pode ser perdido.")

	_stats = UI.label("", "Muted")
	body.add_child(_stats)

	body.add_child(UI.spacer(4))

	var resume := UI.button("CONTINUAR", "PrimaryButton")
	resume.custom_minimum_size = Vector2(0, 46)
	resume.pressed.connect(func() -> void: resume_requested.emit())
	body.add_child(resume)

	var help := UI.button("COMO JOGAR", "GhostButton")
	help.custom_minimum_size = Vector2(0, 42)
	help.pressed.connect(func() -> void: _help.open())
	body.add_child(help)

	var menu := UI.button("SALVAR E VOLTAR AO MENU", "GhostButton")
	menu.custom_minimum_size = Vector2(0, 42)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	body.add_child(menu)

	body.add_child(UI.spacer(6))
	body.add_child(UI.hline(Color(1, 1, 1, 0.07), 1))
	body.add_child(UI.spacer(4))
	body.add_child(UI.label("OPÇÕES", "EyebrowMuted"))

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	body.add_child(volume_row)
	var volume_label := UI.label("Volume geral", "Small")
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(volume_label)
	_volume_value = UI.label("%d%%" % roundi(Settings.master_volume * 100.0), "Tiny")
	volume_row.add_child(_volume_value)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = Settings.master_volume
	slider.custom_minimum_size = Vector2(0, 22)
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set_master_volume(value)
		_volume_value.text = "%d%%" % roundi(value * 100.0)
	)
	body.add_child(slider)

	var fullscreen := CheckButton.new()
	fullscreen.text = "Tela cheia"
	fullscreen.button_pressed = Settings.fullscreen
	fullscreen.toggled.connect(Settings.set_fullscreen)
	body.add_child(fullscreen)

	_help = HELP_PANEL.new()
	add_child(_help)


func _on_open() -> void:
	_stats.text = "Sala: %s  ·  Tempo: %s  ·  Criaturas vistas: %d" % [
		_room_name(GameState.current_room),
		UI.format_time(GameState.play_time),
		GameState.monsters_seen.size(),
	]
	_volume_value.text = "%d%%" % roundi(Settings.master_volume * 100.0)


func handle_cancel() -> bool:
	if _help.visible:
		_help.close()
		return true
	if visible:
		close()
		return true
	return false


func _room_name(room: String) -> String:
	match room:
		"main": return "Sala principal"
		"main_left": return "Lado esquerdo"
		"main_right": return "Lado direito"
		"outside": return "Cais"
		_: return room
