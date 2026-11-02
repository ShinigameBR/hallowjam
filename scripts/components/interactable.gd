class_name Interactable
extends Control
## Base class for everything the player can click in a room.
##
## Attach this (or one of its children: Door, ItemPickup, Examine) directly to
## a TextureRect / Control that wraps your art. In debug builds the node draws
## a small hover outline and the label pill, so it works even before the final
## art exists. Release builds only change the mouse cursor on hover.
##
## Everything is configured from the inspector:
##   Label            -> text shown on hover
##   Interaction Id   -> stable id (used by compatibility calls / custom code)
##   Hide When Flags  -> disappears after these flags are true
##   Show When Flags  -> only visible while all of these flags are true
##   Use Rules        -> reactions to selected inventory items

signal interacted(source: Control, item_id: String)

@export_group("Interaction")
## Stable id for this object. Optional, but useful for tests and custom code.
@export var interaction_id: String = ""
## Label shown when the mouse is over the object.
@export var label: String = ""
## Turn interaction off without hiding the object.
@export var enabled: bool = true

@export_group("Visibility")
## Hidden if any of these flags is true.
@export var hide_when_flags: Array[String] = []
## If not empty, only visible while all of these flags are true.
@export var show_when_flags: Array[String] = []

@export_group("Hover")
## Debug builds only: always draw the label, not only on hover.
@export var always_show_label: bool = false
## Draw the label below the object instead of above it.
@export var label_below: bool = false
## Fine-tune the label position.
@export var label_offset: Vector2 = Vector2.ZERO
@export var outline_enabled: bool = true
@export var cursor_shape: Control.CursorShape = Control.CURSOR_POINTING_HAND

@export_group("Item Usage")
## Optional rules for using inventory items on this object.
@export var use_rules: Array[ItemUseRule] = []

var _hovered := false
var _hover_style: StyleBoxFlat
var _pill_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = cursor_shape
	add_to_group("interactable")

	if label == "":
		label = interaction_id
	tooltip_text = label if _debug_hover_enabled() else ""

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_hover_style = StyleBoxFlat.new()
	_hover_style.bg_color = Color(UI.ACCENT, 0.055)
	_hover_style.border_color = Color(UI.ACCENT, 0.55)
	_hover_style.set_border_width_all(1)
	_hover_style.set_corner_radius_all(7)
	_hover_style.anti_aliasing = true

	_pill_style = StyleBoxFlat.new()
	_pill_style.bg_color = Color(0.035, 0.05, 0.075, 0.96)
	_pill_style.border_color = Color(UI.ACCENT, 0.28)
	_pill_style.set_border_width_all(1)
	_pill_style.set_corner_radius_all(5)
	_pill_style.anti_aliasing = true

	GameState.flags_changed.connect(_refresh_state)
	GameState.selection_changed.connect(_on_selection_changed)
	Settings.debug_hover_changed.connect(_on_debug_hover_changed)

	_refresh_state()
	_ready_extra()


## Optional hook for subclasses. Runs after the base setup.
func _ready_extra() -> void:
	pass


## Public refresh used by the room manager after loading a save / restarting.
func refresh() -> void:
	_refresh_state()


func _refresh_state() -> void:
	var should_show := true

	if show_when_flags.size() > 0:
		for flag in show_when_flags:
			if not GameState.has_flag(flag):
				should_show = false
				break

	if should_show:
		for flag in hide_when_flags:
			if GameState.has_flag(flag):
				should_show = false
				break

	visible = should_show
	if not visible:
		_hovered = false
	queue_redraw()


func _on_mouse_entered() -> void:
	if not visible:
		return
	_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()


func _on_selection_changed() -> void:
	queue_redraw()


## Hover outlines and labels are development aids. They are only drawn while
## debug hover mode is on (default in debug builds, F1 toggles it). A release
## build still gets the pointing-hand cursor from `mouse_default_cursor_shape`.
func _debug_hover_enabled() -> bool:
	return Settings.debug_hover


func _on_debug_hover_changed(enabled: bool) -> void:
	tooltip_text = label if enabled else ""
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not enabled or not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		interact()


## Click handling. Also called by the game root for compatibility/tests.
func interact() -> void:
	if not enabled or not visible:
		return
	if RoomManager.is_changing():
		return

	var selected := GameState.selected_item
	if _try_use_rules(selected):
		return
	_on_interact(selected)
	interacted.emit(self, selected)


## Override in subclasses. `selected_item` is empty when nothing is selected.
func _on_interact(_selected_item: String) -> void:
	pass


func _try_use_rules(selected_item: String) -> bool:
	for rule in use_rules:
		if rule == null:
			continue
		if not _rule_matches(rule, selected_item):
			continue
		_apply_rule(rule, selected_item)
		return true
	return false


func _rule_matches(rule: ItemUseRule, selected_item: String) -> bool:
	if rule.item_id != "":
		if rule.needs_selection:
			if selected_item != rule.item_id:
				return false
		elif not GameState.has_item(rule.item_id):
			return false
	elif rule.needs_selection and selected_item == "":
		return false

	for flag in rule.required_flags:
		if not GameState.has_flag(flag):
			return false
	for flag in rule.forbidden_flags:
		if GameState.has_flag(flag):
			return false
	return true


func _apply_rule(rule: ItemUseRule, selected_item: String) -> void:
	if rule.once_flag != "" and GameState.has_flag(rule.once_flag):
		say(rule.repeat_message if rule.repeat_message != "" else rule.message, rule.speaker)
		return

	if rule.consume_source:
		_consume_source()
	if rule.consume_selected and selected_item != "":
		GameState.remove_item(selected_item)
	if rule.consume_item != "":
		GameState.remove_item(rule.consume_item)
	if rule.give_item != "":
		GameState.add_item(rule.give_item)
	if rule.set_flag != "":
		GameState.set_flag(rule.set_flag)
	if rule.clear_flag != "":
		GameState.clear_flag(rule.clear_flag)
	if rule.once_flag != "":
		GameState.set_flag(rule.once_flag)

	GameState.clear_selection()
	GameState.save_game()

	if rule.message != "":
		say(rule.message, rule.speaker)
	if rule.open_panel != "":
		GameState.panel_requested.emit(rule.open_panel)
	if rule.action_id != "":
		GameState.action_requested.emit(rule.action_id, self)


## Hide this object for the rest of the run. Use flags for persistence.
func _consume_source() -> void:
	visible = false


func say(text: String, speaker: String = "") -> void:
	if text.strip_edges() == "":
		return
	GameState.dialogue_requested.emit([{"speaker": speaker, "text": text}])


func _draw() -> void:
	if not _debug_hover_enabled():
		return
	if not _hovered and not always_show_label:
		return

	var accent := UI.TEAL if GameState.selected_item != "" else UI.ACCENT
	var draw_label := _hovered or always_show_label

	if _hovered and outline_enabled:
		_hover_style.bg_color = Color(accent, 0.06)
		_hover_style.border_color = Color(accent, 0.6)
		draw_style_box(_hover_style, Rect2(Vector2.ZERO, size))

		var c := Color(accent, 0.9)
		var l := minf(14.0, minf(size.x, size.y) * 0.25)
		draw_line(Vector2(0, 0), Vector2(l, 0), c, 1.5, true)
		draw_line(Vector2(0, 0), Vector2(0, l), c, 1.5, true)
		draw_line(Vector2(size.x, 0), Vector2(size.x - l, 0), c, 1.5, true)
		draw_line(Vector2(size.x, 0), Vector2(size.x, l), c, 1.5, true)
		draw_line(Vector2(0, size.y), Vector2(l, size.y), c, 1.5, true)
		draw_line(Vector2(0, size.y), Vector2(0, size.y - l), c, 1.5, true)
		draw_line(Vector2(size.x, size.y), Vector2(size.x - l, size.y), c, 1.5, true)
		draw_line(Vector2(size.x, size.y), Vector2(size.x, size.y - l), c, 1.5, true)

	if not draw_label or label == "":
		return

	_pill_style.border_color = Color(accent, 0.28)
	var text := label
	if GameState.selected_item != "":
		text += "  ·  " + ItemDB.item_name(GameState.selected_item)
	var font := UI.font_medium
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pill_size := Vector2(text_size.x + 22, 26)
	var pill_pos := Vector2((size.x - pill_size.x) * 0.5, -pill_size.y - 8) + label_offset
	if label_below:
		pill_pos.y = size.y + 8 + label_offset.y
	draw_style_box(_pill_style, Rect2(pill_pos, pill_size))
	var baseline := pill_pos.y + pill_size.y * 0.5 + font.get_ascent(font_size) * 0.5 - 1
	draw_string(font, Vector2(pill_pos.x + 11, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(UI.TEXT, 0.95))
