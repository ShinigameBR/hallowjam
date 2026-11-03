extends Control
## Leitor da página do livro: só a arte da página aberta, sem textos, botões
## ou qualquer outro elemento de HUD. Fecha com clique, botão direito ou Esc.

signal closed

const PAGE_ART := preload("res://assets/props/pagina_do_livro_aberta.jpeg")

var _closing := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var backdrop := ColorRect.new()
	backdrop.color = UI.BLACK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var page := TextureRect.new()
	page.texture = PAGE_ART
	page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 24
	page.offset_top = 24
	page.offset_right = -24
	page.offset_bottom = -24
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)


func open() -> void:
	if visible:
		return
	_closing = false
	visible = true
	modulate.a = 0.0
	if not GameState.has_flag("book_read"):
		GameState.set_flag("book_read", true)
		GameState.save_game()
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)


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
	closed.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			accept_event()
			close()
