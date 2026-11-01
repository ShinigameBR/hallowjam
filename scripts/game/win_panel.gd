extends "res://scripts/game/overlay.gd"
## Ending card for the vertical slice.

signal menu_requested
signal restart_requested

const GLYPH := preload("res://scripts/game/monster_glyph.gd")

var _stats: Label


func _build() -> void:
	panel.custom_minimum_size = Vector2(680, 0)

	body.add_child(UI.label("FIM DO PROTÓTIPO", "Eyebrow"))

	var glyph := GLYPH.new()
	glyph.setup("verde")
	glyph.custom_minimum_size = Vector2(240, 240)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(glyph)

	var title := UI.label("O ritual se completa.", "H1")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)

	var text := UI.label(
		"O Errante Verde mergulha sem fazer barulho e espera por você. A cabana fica para trás, com suas luzes e seus livros e a coisa que ainda respira no porão.\n\nDo outro lado da maré, alguém vai acordar em casa.",
		"BodyLarge"
	)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.custom_minimum_size = Vector2(560, 0)
	body.add_child(text)

	body.add_child(UI.spacer(6))

	_stats = UI.label("", "Muted")
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_stats)

	body.add_child(UI.spacer(8))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)

	var restart := UI.button("JOGAR NOVAMENTE", "PrimaryButton")
	restart.custom_minimum_size = Vector2(210, 46)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	row.add_child(restart)

	var menu := UI.button("VOLTAR AO MENU", "GhostButton")
	menu.custom_minimum_size = Vector2(190, 46)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	row.add_child(menu)


func show_win() -> void:
	_stats.text = "Tempo: %s  ·  Criaturas vistas: %d" % [
		UI.format_time(GameState.play_time),
		GameState.monsters_seen.size(),
	]
	open()


## The ending is terminal; only its own buttons leave this card.
func _on_dim_input(_event: InputEvent) -> void:
	pass
