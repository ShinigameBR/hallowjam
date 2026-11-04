extends "res://scripts/game/overlay.gd"
## The wizard's diary, presented as a warm parchment page against the dark UI.

var _seen_label: Label


func _build() -> void:
	panel.custom_minimum_size = Vector2(780, 0)

	body.add_child(UI.label("DIÁRIO DO BRUXO", "Eyebrow"))
	body.add_child(UI.label("As últimas páginas.", "H1"))
	body.add_child(UI.spacer(4))
	body.add_child(UI.hline(Color(UI.ACCENT, 0.24), 1))
	body.add_child(UI.spacer(6))

	var paper := PanelContainer.new()
	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = Color("#cfc4a8")
	paper_style.border_color = Color("#8f7743")
	paper_style.set_border_width_all(1)
	paper_style.set_corner_radius_all(5)
	paper_style.set_content_margin_all(24)
	paper_style.anti_aliasing = true
	paper.add_theme_stylebox_override("panel", paper_style)
	body.add_child(paper)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	paper.add_child(page)

	_page_line(page, "Terceira noite. O círculo não me obedece porque eu tenho medo. Ele sente isso.")
	_page_line(page, "O Carmesim atende a duas coisas: algo vermelho e um aroma floral. Não vem por força: vem por cheiro.")
	_page_line(page, "A lavanda do lado direito morreu há anos. A poção violeta ainda pode trazê-la de volta.")
	_page_line(page, "Se eu não voltar, que alguém termine o que eu comecei.")

	var signature := UI.label("— E.", "Small")
	signature.add_theme_color_override("font_color", Color("#5a4a32"))
	signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page.add_child(signature)

	body.add_child(UI.spacer(4))
	var note := UI.label("A letra fica mais apressada no fim.", "Tiny")
	body.add_child(note)

	var close_button := UI.button("FECHAR", "PrimaryButton")
	close_button.custom_minimum_size = Vector2(150, 42)
	close_button.pressed.connect(close)
	_add_footer([close_button])


func _page_line(parent: VBoxContainer, text: String) -> void:
	var label := UI.label(text, "BodyLarge")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#2b2118"))
	label.add_theme_constant_override("line_spacing", 4)
	label.custom_minimum_size = Vector2(660, 0)
	parent.add_child(label)


func _on_open() -> void:
	if not GameState.has_flag("diary_read"):
		GameState.set_flag("diary_read", true)
		GameState.save_game()
