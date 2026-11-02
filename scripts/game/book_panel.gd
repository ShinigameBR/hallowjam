extends "res://scripts/game/overlay.gd"
## The wizard's grimoire: the target creature, its qualities and the
## coloured-book count that opens the strongbox.

const GLYPH := preload("res://scripts/game/monster_glyph.gd")

var _seen_label: Label


func _build() -> void:
	panel.custom_minimum_size = Vector2(840, 0)

	body.add_child(UI.label("O LIVRO DO BRUXO", "Eyebrow"))
	body.add_child(UI.label("A página que ficou aberta.", "H1"))
	body.add_child(UI.spacer(4))
	body.add_child(UI.hline(Color(UI.ACCENT, 0.24), 1))
	body.add_child(UI.spacer(6))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	body.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(250, 0)
	left.add_theme_constant_override("separation", 4)
	columns.add_child(left)

	var glyph := GLYPH.new()
	glyph.setup("carmesim")
	glyph.custom_minimum_size = Vector2(230, 230)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(glyph)

	var name_label := UI.label("O Beija-Flor Carmesim", "H2")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(name_label)

	var title := UI.label("Mensageiro fiel", "Muted")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(title)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)

	right.add_child(UI.label("PÁGINA DO RITUAL", "EyebrowMuted"))
	var intro := UI.label("Para abrir a porta do sótão, o bruxo precisava de um mensageiro que atendesse ao chamado e pudesse ser alimentado. O livro descreve o Carmesim e as duas qualidades que o atraem.", "Muted")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(460, 0)
	right.add_child(intro)
	right.add_child(UI.spacer(4))

	var hints: Array = ItemDB.monster("carmesim").get("hints", [])
	for i in range(hints.size()):
		right.add_child(_hint_row("%02d" % (i + 1), String(hints[i])))

	right.add_child(UI.spacer(6))

	var clue := UI.panel("PagePanel")
	var clue_margin := MarginContainer.new()
	clue_margin.add_theme_constant_override("margin_left", 18)
	clue_margin.add_theme_constant_override("margin_right", 18)
	clue_margin.add_theme_constant_override("margin_top", 14)
	clue_margin.add_theme_constant_override("margin_bottom", 14)
	clue.add_child(clue_margin)
	var clue_box := VBoxContainer.new()
	clue_box.add_theme_constant_override("separation", 6)
	clue_margin.add_child(clue_box)

	clue_box.add_child(UI.label("A ESTANTE", "Eyebrow"))
	var clue_text := UI.label("O bruxo organizava os livros por cor. O cofre pede as cores nesta ordem, e as quantidades estão nos livros:", "Muted")
	clue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue_text.custom_minimum_size = Vector2(430, 0)
	clue_box.add_child(clue_text)

	var colors := HBoxContainer.new()
	colors.add_theme_constant_override("separation", 20)
	clue_box.add_child(colors)
	colors.add_child(_color_count("AZUL", "3", Color("#405f8a")))
	colors.add_child(_color_count("VERMELHO", "1", Color("#7a3a45")))
	colors.add_child(_color_count("VERDE", "4", Color("#4e7a54")))
	colors.add_child(_color_count("AMARELO", "2", Color("#8a7436")))

	right.add_child(clue)

	_seen_label = UI.label("", "Tiny")
	_seen_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_seen_label)

	var close_button := UI.button("FECHAR", "PrimaryButton")
	close_button.custom_minimum_size = Vector2(150, 42)
	close_button.pressed.connect(close)
	_add_footer([close_button])


func _hint_row(number: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var num := UI.label(number, "Eyebrow")
	num.custom_minimum_size = Vector2(28, 0)
	num.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	row.add_child(num)
	var body_label := UI.label(text, "BodyLarge")
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.custom_minimum_size = Vector2(400, 0)
	row.add_child(body_label)
	return row


func _color_count(name: String, count: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(11, 11)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(swatch)
	# var label := UI.label("%s %s" % [name, count], "Small")
	var label := UI.label("%s %s" % [name, count], "Small")
	row.add_child(label)
	return row


func _on_open() -> void:
	if not GameState.has_flag("shelf_seen"):
		GameState.set_flag("shelf_seen", true)
		GameState.save_game()

	if GameState.monsters_seen.is_empty():
		_seen_label.text = "Nenhuma criatura atendeu ao chamado ainda."
	else:
		var names: Array[String] = []
		for id in GameState.monsters_seen:
			names.append(String(ItemDB.monster(id).get("name", id)))
		_seen_label.text = "Já invocados: " + " · ".join(names)
