extends "res://scripts/game/overlay.gd"
## The wizard's grimoire: the target creature and its qualities.

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
