extends HBoxContainer
## Reusable inventory strip. The HUD uses it as a viewer (auto_select = false)
## while the circle panel lets it drive the global selection directly.

signal item_clicked(id: String)

const ITEM_ICON := preload("res://scripts/game/item_icon.gd")

var auto_select := true
var _borders: Array = []


func _ready() -> void:
	theme = UI.theme
	add_theme_constant_override("separation", 8)
	GameState.inventory_changed.connect(_refresh)
	GameState.selection_changed.connect(_refresh_selection)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_borders.clear()

	for id in GameState.inventory:
		var slot := Button.new()
		slot.theme_type_variation = "SlotButton"
		slot.custom_minimum_size = Vector2(56, 56)
		slot.tooltip_text = ItemDB.item_name(id) + "\n" + ItemDB.tags_text(ItemDB.item_tags(id))
		slot.pressed.connect(_on_slot_pressed.bind(id))
		add_child(slot)

		var icon := ITEM_ICON.new()
		icon.setup(id)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 7
		icon.offset_top = 7
		icon.offset_right = -7
		icon.offset_bottom = -7

		var border := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_color = UI.ACCENT
		style.set_border_width_all(2)
		style.set_corner_radius_all(9)
		style.anti_aliasing = true
		border.add_theme_stylebox_override("panel", style)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(border)
		border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_borders.append({"id": id, "node": border})

	_refresh_selection()


func _refresh_selection() -> void:
	for entry in _borders:
		var node: Panel = entry.get("node")
		if is_instance_valid(node):
			node.visible = String(entry.get("id")) == GameState.selected_item


func _on_slot_pressed(id: String) -> void:
	item_clicked.emit(id)
	if auto_select:
		GameState.select_item(id)
