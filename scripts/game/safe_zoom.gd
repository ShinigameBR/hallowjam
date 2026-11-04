extends Control
## Zoom no baú da estante: só a imagem e quatro números coloridos.
## Cada clique num número soma 1 (0 1 2 3 4 5 e volta para 0).
## Quando a combinação fica certa, o baú abre sozinho e o rubi pode ser pego.
##
## Combinação correta: vermelho 2, azul 1, amarelo 2, verde 1.
## Esc ou botão direito do mouse fecham o zoom.

signal solved
signal closed

# ---- A resposta certa. Os nomes são os nomes dos nodes na cena. ----
const TARGET := {"Red": 2, "Blue": 1, "Yellow": 2, "Green": 1}
const COLORS := {
	"Red": Color("#cf5d63"),
	"Blue": Color("#6d9fd1"),
	"Yellow": Color("#d8b63c"),
	"Green": Color("#6fbf8a"),
}
const MAX_NUMBER := 5
const NUMBER_FONT_SIZE := 24

const CHEST_IMG := preload("res://assets/backgrounds/bau.jpeg")
const CHEST_OPEN_IMG := preload("res://assets/backgrounds/bau_aberto.jpeg")

@onready var _background: TextureRect = $Background
@onready var _ruby: Button = $Background/Ruby

var _counts := {}
var _opened := false
var _closing := false


func _ready() -> void:
	theme = UI.theme
	visible = false
	for color_name in TARGET:
		var button: Button = _background.get_node(color_name)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, COLORS[color_name])
		button.add_theme_font_size_override("font_size", NUMBER_FONT_SIZE)
		button.pressed.connect(_on_number_pressed.bind(color_name))
	_ruby.pressed.connect(_take_ruby)
	UI.add_close_hint(self)


# ============================================================ NÚMEROS
func _on_number_pressed(color_name: String) -> void:
	if _opened or _closing:
		return
	_counts[color_name] = (_counts[color_name] + 1) % (MAX_NUMBER + 1)
	_background.get_node(color_name).text = str(_counts[color_name])
	if _is_correct():
		# Grava no save que o baú foi aberto, mesmo que o rubi não seja pego agora.
		GameState.set_flag("chest_open", true)
		GameState.save_game()
		_reveal_chest()


func _is_correct() -> bool:
	for color_name in TARGET:
		if _counts.get(color_name, -1) != TARGET[color_name]:
			return false
	return true


func _set_numbers_visible(value: bool) -> void:
	for color_name in TARGET:
		_background.get_node(color_name).visible = value


# ============================================================ BAÚ E RUBI
func _reveal_chest() -> void:
	_opened = true
	# Pequena pausa para o jogador ver o último número antes de abrir.
	await get_tree().create_timer(0.35).timeout
	# Se o jogador fechou durante a pausa, ou reabriu e o baú já aparece aberto, não faz nada.
	if not visible or _closing or not _opened or _ruby.visible:
		return
	_show_open_state()
	_zoom(1.05, 0.4)


# Baú aberto: imagem aberta, números escondidos e rubi clicável.
func _show_open_state() -> void:
	_opened = true
	_background.texture = CHEST_OPEN_IMG
	_set_numbers_visible(false)
	_ruby.visible = true


func _take_ruby() -> void:
	# Evita pegar duas vezes com cliques rápidos.
	if _closing or GameState.has_flag("ruby_taken"):
		return
	if not GameState.has_item("ruby"):
		GameState.add_item("ruby")
	GameState.set_flag("safe_open", true)
	GameState.set_flag("ruby_taken", true)
	GameState.save_game()
	solved.emit()
	close()


# Volta tudo ao começo: baú fechado e todos os números em 0.
func _reset() -> void:
	_opened = false
	_background.texture = CHEST_IMG
	for color_name in TARGET:
		_counts[color_name] = 0
		_background.get_node(color_name).text = "0"
	_set_numbers_visible(true)
	_ruby.visible = false


# ============================================================ ABRIR / FECHAR
# O game.gd chama open() e close(). Esc também chama close().
func open() -> void:
	if visible or GameState.has_flag("safe_open"):
		return
	_closing = false
	visible = true
	# Se o baú já foi aberto antes (e o rubi não foi pego), volta direto para ele aberto.
	if GameState.has_flag("chest_open"):
		_show_open_state()
	else:
		_reset()
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
# Os números são filhos do Background, então acompanham o zoom.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2.ONE, time)
