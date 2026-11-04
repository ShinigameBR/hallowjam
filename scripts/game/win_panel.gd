extends "res://scripts/game/overlay.gd"
## Ending card for the vertical slice.

signal menu_requested
signal restart_requested

const ART := preload("res://assets/backgrounds/fim_do_jogo.png")

var _stats: Label


func _build() -> void:
	panel.custom_minimum_size = Vector2(680, 0)

	body.add_child(UI.label("FIM DO PROTÓTIPO", "Eyebrow"))

	var art := TextureRect.new()
	art.texture = ART
	art.custom_minimum_size = Vector2(600, 295)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(art)

	var title := UI.label("A primeira porta se abre.", "H1")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)

	var text := UI.label(
		"O Carmesim devora o peixe e força a porta do sótão. O escuro lá em cima cheira a poeira, madeira velha e metal molhado.\n\nO sótão, a maleta e a última invocação ficam para o próximo capítulo.",
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
