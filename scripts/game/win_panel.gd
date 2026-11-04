extends Control
## Full-screen ending. The final illustration behaves like a room backdrop,
## with the closing text, statistics and actions sitting over its lower edge.

signal menu_requested
signal restart_requested

const ART := preload("res://assets/backgrounds/fim_do_jogo.png")

## Content container exposed for the layout test.
var panel: VBoxContainer

var _stats: Label
var _closing := false


func _ready() -> void:
	theme = UI.theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func _build() -> void:
	var art := TextureRect.new()
	art.texture = ART
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	# Escurece só a parte de baixo para o texto continuar legível.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.02, 0.03, 0.05, 0.0))
	gradient.set_color(1, Color(0.02, 0.03, 0.05, 0.96))
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)

	var scrim := TextureRect.new()
	scrim.texture = gradient_texture
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	panel = VBoxContainer.new()
	panel.name = "EndingContent"
	panel.anchor_left = 0.10
	panel.anchor_top = 0.40
	panel.anchor_right = 0.90
	panel.anchor_bottom = 0.94
	panel.alignment = BoxContainer.ALIGNMENT_END
	panel.add_theme_constant_override("separation", 8)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var eyebrow := UI.label("FIM", "Eyebrow")
	_center_label(eyebrow)
	panel.add_child(eyebrow)

	var title := UI.label("O mar te reconhece.", "H1")
	_center_label(title)
	panel.add_child(title)

	var text := UI.label(
		"O Cego das Profundezas sobe do círculo e o mar sobe com ele. A cabana, o sótão e a escama azul afundam devagar, sem pressa.\n\nQuando a água fecha sobre a sua cabeça, você não sente medo. Só o peso de finalmente estar em casa.",
		"BodyLarge"
	)
	_center_label(text)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(text)

	_stats = UI.label("", "Muted")
	_center_label(_stats)
	panel.add_child(_stats)

	panel.add_child(UI.spacer(8))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var restart := UI.button("JOGAR NOVAMENTE", "PrimaryButton")
	restart.custom_minimum_size = Vector2(210, 46)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	row.add_child(restart)

	var menu := UI.button("SAIR", "GhostButton")
	menu.custom_minimum_size = Vector2(190, 46)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	row.add_child(menu)


func _center_label(label: Label) -> void:
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func show_win() -> void:
	_stats.text = "Tempo: %s" % UI.format_time(GameState.play_time)
	_closing = false
	if visible:
		return
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.8)


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
