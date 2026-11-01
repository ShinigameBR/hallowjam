extends Control
## Invisible clickable region over a painted object.
## Reveals its name and a clean outline only on hover.

signal pressed(id: String)

var id: String = ""
var label: String = ""
var selected_item_id: String = ""
var hovered := false

var _hover_style: StyleBoxFlat
var _pill_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
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


func setup(hotspot_id: String, hotspot_label: String) -> void:
	id = hotspot_id
	label = hotspot_label
	tooltip_text = hotspot_label


func set_selected_item(item_id: String) -> void:
	selected_item_id = item_id
	queue_redraw()


func _on_enter() -> void:
	hovered = true
	queue_redraw()


func _on_exit() -> void:
	hovered = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		pressed.emit(id)


func _draw() -> void:
	if not hovered:
		return
	var accent := UI.TEAL if selected_item_id != "" else UI.ACCENT
	_hover_style.bg_color = Color(accent, 0.06)
	_hover_style.border_color = Color(accent, 0.6)
	draw_style_box(_hover_style, Rect2(Vector2.ZERO, size))

	# corner ticks
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

	var text := label
	if selected_item_id != "":
		text += "  ·  " + ItemDB.item_name(selected_item_id)
	var font := UI.font_medium
	var font_size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pill_size := Vector2(text_size.x + 22, 26)
	var above := global_position.y > 46
	var pill_pos := Vector2((size.x - pill_size.x) * 0.5, -pill_size.y - 8)
	if not above:
		pill_pos.y = size.y + 8
	draw_style_box(_pill_style, Rect2(pill_pos, pill_size))
	var baseline := pill_pos.y + pill_size.y * 0.5 + font.get_ascent(font_size) * 0.5 - 1
	draw_string(font, Vector2(pill_pos.x + 11, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(UI.TEXT, 0.95))
