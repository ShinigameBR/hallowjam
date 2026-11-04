extends Control
## Reusable "how to play" overlay, opened from both the menu and the pause screen.

signal closed

var _panel: PanelContainer
var _dim: ColorRect


func _ready() -> void:
	theme = UI.theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.05, 0.78)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	box.add_child(UI.label("COMO JOGAR", "Eyebrow"))
	var title := UI.label("A cabana não devolve o que toma.", "H1")
	box.add_child(title)
	box.add_child(UI.spacer(6))
	box.add_child(UI.hline(Color(UI.ACCENT, 0.28), 1))
	box.add_child(UI.spacer(10))

	_add_rule(box, "01", "Explore", "Clique nos objetos do cenário para examinar. Alguns podem ser guardados no inventário.")
	_add_rule(box, "02", "Use", "Selecione um item na barra inferior e clique no cenário para usá-lo. Clique com o botão direito para soltar o item.")
	_add_rule(box, "03", "Invoque", "O círculo mágico aceita quatro oferendas. O monstro resultante nasce das qualidades dos ingredientes, não dos nomes.")
	_add_rule(box, "04", "Leia", "A página do livro mostra o monstro necessário. O diário do bruxo revela a receita completa.")
	_add_rule(box, "05", "Respire", "ESC fecha janelas e abre o menu. Não há como perder: só caminhos que ainda não foram encontrados.")

	box.add_child(UI.spacer(10))
	box.add_child(UI.hline(Color(1, 1, 1, 0.07), 1))
	box.add_child(UI.spacer(6))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(footer)
	var back := UI.button("VOLTAR", "PrimaryButton")
	back.custom_minimum_size = Vector2(150, 42)
	back.pressed.connect(close)
	footer.add_child(back)


func _add_rule(parent: VBoxContainer, number: String, title: String, body: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var num := UI.label(number, "Eyebrow")
	num.custom_minimum_size = Vector2(34, 0)
	num.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	row.add_child(num)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	text_box.add_child(UI.label(title, "H2"))
	var body_label := UI.label(body, "Muted")
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(560, 0)
	text_box.add_child(body_label)


func open() -> void:
	visible = true
	modulate.a = 0.0
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.98, 0.98)
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25)


func close() -> void:
	if not visible:
		return
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.16)
	await tw.finished
	visible = false
	closed.emit()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close()
