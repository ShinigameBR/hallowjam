extends "res://scripts/game/overlay.gd"
## The magic circle: four offering slots, a live quality readout and a
## compact inventory strip so the player never has to leave the ritual.

signal summon_requested

const ITEM_ICON := preload("res://scripts/game/item_icon.gd")
const INVENTORY_BAR := preload("res://scripts/game/inventory_bar.gd")

var _slot_buttons: Array[Button] = []
var _tags_label: Label
var _hint_label: Label
var _summon_button: Button
var _clear_button: Button
var _bar: HBoxContainer


func _build() -> void:
	panel.custom_minimum_size = Vector2(780, 0)

	_add_header("O CÍRCULO", "Quatro oferendas.", "As qualidades dos ingredientes decidem quem atende. Não os nomes.")

	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 14)
	body.add_child(slots)

	for i in range(4):
		var button := Button.new()
		button.theme_type_variation = "SlotButton"
		button.custom_minimum_size = Vector2(112, 112)
		button.pressed.connect(_on_slot_pressed.bind(i))
		slots.add_child(button)
		_slot_buttons.append(button)

	body.add_child(UI.spacer(4))

	_tags_label = UI.label("", "Muted")
	_tags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_tags_label)

	_hint_label = UI.label("Selecione um ingrediente e clique em um espaço.", "Tiny")
	body.add_child(_hint_label)

	body.add_child(UI.spacer(4))
	body.add_child(UI.label("OFERENDAS DISPONÍVEIS", "EyebrowMuted"))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 86)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	_bar = INVENTORY_BAR.new()
	_bar.auto_select = true
	scroll.add_child(_bar)

	body.add_child(UI.spacer(6))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	body.add_child(footer)

	_clear_button = UI.button("LIMPAR", "GhostButton")
	_clear_button.custom_minimum_size = Vector2(130, 42)
	_clear_button.pressed.connect(GameState.clear_circle)
	footer.add_child(_clear_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var close_button := UI.button("FECHAR", "GhostButton")
	close_button.custom_minimum_size = Vector2(130, 42)
	close_button.pressed.connect(close)
	footer.add_child(close_button)

	_summon_button = UI.button("INVOCAR", "PrimaryButton")
	_summon_button.custom_minimum_size = Vector2(170, 42)
	_summon_button.pressed.connect(func() -> void: summon_requested.emit())
	footer.add_child(_summon_button)

	GameState.circle_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh)
	GameState.selection_changed.connect(_refresh)
	_refresh()


func _on_open() -> void:
	_refresh()


func _on_slot_pressed(index: int) -> void:
	if GameState.circle[index] != "":
		GameState.take_from_circle(index)
		return
	if GameState.selected_item == "":
		GameState.notify("Selecione um ingrediente no inventário.")
		return
	if not GameState.place_in_circle(index, GameState.selected_item):
		GameState.notify("Esse espaço já está ocupado.")


func _refresh() -> void:
	for i in range(4):
		_fill_slot(_slot_buttons[i], GameState.circle[i])

	var tags := ItemDB.collect_tags(GameState.circle)
	if tags.is_empty():
		_tags_label.text = "Nenhuma qualidade no círculo ainda."
	else:
		var keys: Array = tags.keys()
		keys.sort()
		_tags_label.text = "Qualidades presentes: " + ItemDB.tags_text(keys)

	var filled := 0
	for id in GameState.circle:
		if id != "":
			filled += 1

	if _summon_button:
		_summon_button.disabled = filled == 0
	if _clear_button:
		_clear_button.disabled = filled == 0

	if GameState.selected_item != "":
		_hint_label.text = "Usando: %s. Clique em um espaço vazio." % ItemDB.item_name(GameState.selected_item)
	else:
		_hint_label.text = "Selecione um ingrediente e clique em um espaço."


func _fill_slot(button: Button, item_id: String) -> void:
	for child in button.get_children():
		button.remove_child(child)
		child.queue_free()
	button.text = ""

	if item_id == "":
		var plus := UI.label("+", "TitleSmall")
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus.add_theme_color_override("font_color", Color(UI.MUTED, 0.55))
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(plus)
		plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return

	var icon := ITEM_ICON.new()
	icon.setup(item_id)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 18
	icon.offset_top = 8
	icon.offset_right = -18
	icon.offset_bottom = -32

	var label := UI.label(ItemDB.item_name(item_id), "Tiny")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 6
	label.offset_right = -6
	label.offset_top = 76
	label.offset_bottom = -7
