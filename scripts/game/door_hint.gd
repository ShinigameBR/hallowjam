extends Control
## Dica na porta da frente: só a imagem, nada clicável dentro.
##
## Sai com Esc, botão direito ou game.gd chamando close().

signal closed

@onready var _background: TextureRect = $Background

var _closing := false


func _ready() -> void:
	theme = UI.theme
	visible = false


# ============================================================ ABRIR / FECHAR
# O game.gd chama open() e close(). Esc também chama close().
func open() -> void:
	if visible:
		return
	_closing = false
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	_zoom(1.15, 0.7)   # a "aproximação" da câmera


func close() -> void:
	if not visible or _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	await tw.finished
	visible = false
	_closing = false
	closed.emit()


# Botão direito do mouse também fecha.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		accept_event()
		close()


# Começa a imagem maior e encolhe até o normal: parece a câmera chegando.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2.ONE, time)
