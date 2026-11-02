extends "res://scripts/game/overlay.gd"
## Strongbox keypad. The order is printed on the frame; the counts live on
## the bookshelf. Correct code: 3 1 4 2 (blue, red, green, yellow).

signal solved

const CODE := "3142"

var _entry := ""
var _digits: Array[Label] = []
var _status: Label


func _build() -> void:
	panel.custom_minimum_size = Vector2(470, 0)
	body.add_theme_constant_override("separation", 7)

	_add_header("O COFRE", "Quatro números.", "A ordem está gravada na moldura. As quantidades estão na estante.")

	var order := HBoxContainer.new()
	order.alignment = BoxContainer.ALIGNMENT_CENTER
	order.add_theme_constant_override("separation", 14)
	body.add_child(order)
	order.add_child(_order_chip("AZUL", Color("#405f8a")))
	order.add_child(_order_chip("VERMELHO", Color("#7a3a45")))
	order.add_child(_order_chip("VERDE", Color("#4e7a54")))
	order.add_child(_order_chip("AMARELO", Color("#8a7436")))

	body.add_child(UI.spacer(4))

	var display := HBoxContainer.new()
	display.alignment = BoxContainer.ALIGNMENT_CENTER
	display.add_theme_constant_override("separation", 10)
	body.add_child(display)
	for i in range(4):
		var box := PanelContainer.new()
		box.theme_type_variation = "KeypadPanel"
		box.custom_minimum_size = Vector2(62, 58)
		display.add_child(box)
		var digit := UI.label("·", "H1")
		digit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		digit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(digit)
		_digits.append(digit)

	body.add_child(UI.spacer(4))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)

	for n in range(1, 10):
		grid.add_child(_digit_button(str(n)))
	var clear_button := UI.button("LIMPAR", "GhostButton")
	clear_button.custom_minimum_size = Vector2(96, 42)
	clear_button.pressed.connect(_clear)
	grid.add_child(clear_button)
	grid.add_child(_digit_button("0"))
	var open_button := UI.button("ABRIR", "PrimaryButton")
	open_button.custom_minimum_size = Vector2(96, 42)
	open_button.pressed.connect(_submit)
	grid.add_child(open_button)

	_status = UI.label("", "Muted")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_status)

	var close_button := UI.button("FECHAR", "GhostButton")
	close_button.custom_minimum_size = Vector2(140, 40)
	close_button.pressed.connect(close)
	_add_footer([close_button])


func _order_chip(text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(9, 9)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(swatch)
	row.add_child(UI.label(text, "Tiny"))
	return row


func _digit_button(value: String) -> Button:
	var b := UI.button(value, "KeypadButton")
	b.custom_minimum_size = Vector2(96, 42)
	b.pressed.connect(_press_digit.bind(value))
	return b


func _press_digit(value: String) -> void:
	if _entry.length() >= 4:
		return
	_entry += value
	_status.text = ""
	_refresh_display()


func _clear() -> void:
	_entry = ""
	_status.text = ""
	_refresh_display()


func _refresh_display() -> void:
	for i in range(4):
		_digits[i].text = _entry[i] if i < _entry.length() else "·"


func _submit() -> void:
	if _entry.length() < 4:
		_status.text = "Faltam números."
		return
	if _entry == CODE:
		GameState.set_flag("safe_open", true)
		if not GameState.has_item("ruby"):
			GameState.add_item("ruby")
		GameState.set_flag("ruby_taken", true)
		GameState.save_game()
		_status.text = "O cofre cede. Dentro, um rubi vermelho."
		solved.emit()
		close()
		return

	_status.text = "O cofre não cede."
	_entry = ""
	_refresh_display()
	var tw := create_tween()
	tw.tween_property(panel, "modulate", Color(1.0, 0.62, 0.62), 0.07)
	tw.tween_property(panel, "modulate", Color.WHITE, 0.18)


func _on_open() -> void:
	_entry = ""
	_status.text = ""
	_refresh_display()
