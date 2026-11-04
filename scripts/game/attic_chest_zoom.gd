extends Control
## Zoom no baú do sótão: só a imagem e cinco números giram de 0 a 5.
## Cada clique num número soma 1 (0 1 2 3 4 5 e volta para 0).
## Quando a combinação fica certa, o baú abre e o sótão troca para a imagem
## com o baú já aberto, onde a escama azul pode ser pega.
##
## Combinação correta: 3 1 5 4 2.
## Esc ou botão direito do mouse fecham o zoom.

signal solved
signal closed

# ---- A resposta certa, na ordem dos cinco discos. ----
const TARGET: Array[int] = [3, 1, 5, 4, 2]
const DIALS: Array[String] = ["Dial1", "Dial2", "Dial3", "Dial4", "Dial5"]
const MAX_NUMBER := 5
const NUMBER_FONT_SIZE := 64
const NUMBER_COLOR := Color("#e8dcc0")
## A arte é mais larga que a tela; um leve recuo mostra as laterais inteiras.
const BASE_SCALE := 0.87

@onready var _background: TextureRect = $Background

var _counts: Array[int] = [0, 0, 0, 0, 0]
var _opened := false
var _closing := false


func _ready() -> void:
	theme = UI.theme
	visible = false
	for index in DIALS.size():
		var button: Button = _background.get_node(DIALS[index])
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, NUMBER_COLOR)
		button.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.9))
		button.add_theme_constant_override("outline_size", 10)
		button.add_theme_font_size_override("font_size", NUMBER_FONT_SIZE)
		button.pressed.connect(_on_dial_pressed.bind(index))
	UI.add_close_hint(self)


# ============================================================ NÚMEROS
func _on_dial_pressed(index: int) -> void:
	if _opened or _closing:
		return
	_counts[index] = (_counts[index] + 1) % (MAX_NUMBER + 1)
	_background.get_node(DIALS[index]).text = str(_counts[index])
	if _is_correct():
		# Grava no save que o baú foi aberto. O fundo do sótão reage à flag.
		_opened = true
		GameState.set_flag("attic_chest_open", true)
		GameState.save_game()
		solved.emit()
		# Pequena pausa para o jogador ver o último número antes de fechar.
		await get_tree().create_timer(0.35).timeout
		if visible and not _closing:
			close()


func _is_correct() -> bool:
	for index in TARGET.size():
		if _counts[index] != TARGET[index]:
			return false
	return true


# Volta tudo ao começo: todos os discos em 0.
func _reset() -> void:
	_opened = false
	for index in DIALS.size():
		_counts[index] = 0
		_background.get_node(DIALS[index]).text = "0"


# ============================================================ ABRIR / FECHAR
# O game.gd chama open() e close(). Esc também chama close().
func open() -> void:
	if visible or GameState.has_flag("attic_chest_open"):
		return
	_closing = false
	visible = true
	_reset()
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	_zoom(1.0, 0.7)   # a "aproximação" da câmera


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
# Os números são filhos do Background, então acompanham o zoom.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2(BASE_SCALE, BASE_SCALE), time)
