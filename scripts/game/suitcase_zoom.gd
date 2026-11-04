extends Control
## Zoom na maleta aberta pelo inventário: dois relógios lado a lado.
## O ponteiro do sol marca as horas e o da lua marca os minutos.
## Cada clique num relógio gira o ponteiro uma casa no sentido horário
## (12 casas, como um relógio comum; o tempo de verdade não importa).
##
## Resposta: sol no 3 (3 horas) e lua no 11 (os minutos).
## Com os dois certos, a maleta destrava, o jogador ganha a caixa de música
## e o zoom fecha sozinho. Esc ou botão direito do mouse fecham o zoom.

signal solved
signal closed

# ---- A resposta certa: número do relógio para onde cada ponteiro aponta. ----
const SUN_TARGET := 3
const MOON_TARGET := 11
const STEPS := 12

## Centro de giro de cada ponteiro, em pixels da PNG (o meio do sol / da lua).
const SUN_PIVOT := Vector2(101, 228)
const MOON_PIVOT := Vector2(93, 240)
## Tamanho dos ponteiros na tela em relação à PNG.
const HAND_SCALE := 0.55
## Distância dos números até o centro do relógio, em pixels da tela.
const NUMBER_RADIUS := 96.0
const NUMBER_FONT_SIZE := 18
const NUMBER_COLOR := Color("#3a3128")

@onready var _background: TextureRect = $Background
@onready var _sun_dial: Button = $Background/SunDial
@onready var _moon_dial: Button = $Background/MoonDial
@onready var _sun_hand: TextureRect = $Background/SunDial/Hand
@onready var _moon_hand: TextureRect = $Background/MoonDial/Hand

## Posição de cada ponteiro: 0 = 12, 1 = 1, 2 = 2, ... 11 = 11.
var _sun := 0
var _moon := 0
var _solved := false
var _closing := false
var _hand_tweens := {}


func _ready() -> void:
	theme = UI.theme
	visible = false
	_place_hand(_sun_hand, SUN_PIVOT)
	_place_hand(_moon_hand, MOON_PIVOT)
	for dial in [_sun_dial, _moon_dial]:
		dial.draw.connect(_draw_numbers.bind(dial))
	_sun_dial.pressed.connect(_on_sun_pressed)
	_moon_dial.pressed.connect(_on_moon_pressed)
	UI.add_close_hint(self)


# Põe o centro do sol/da lua bem no meio do relógio e gira em volta dele.
func _place_hand(hand: TextureRect, pivot: Vector2) -> void:
	var hand_size := hand.texture.get_size() * HAND_SCALE
	var pivot_on_screen := pivot * HAND_SCALE
	hand.anchor_left = 0.5
	hand.anchor_top = 0.5
	hand.anchor_right = 0.5
	hand.anchor_bottom = 0.5
	hand.offset_left = -pivot_on_screen.x
	hand.offset_top = -pivot_on_screen.y
	hand.offset_right = hand.offset_left + hand_size.x
	hand.offset_bottom = hand.offset_top + hand_size.y
	hand.pivot_offset = pivot_on_screen


# Os números de 1 a 12 em volta de cada relógio.
func _draw_numbers(dial: Button) -> void:
	var font := UI.font_title
	var center := dial.size * 0.5
	for number in range(1, STEPS + 1):
		var angle := TAU * number / STEPS - PI * 0.5
		var spot := center + Vector2(cos(angle), sin(angle)) * NUMBER_RADIUS
		var text := str(number)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE)
		var baseline := spot + Vector2(-text_size.x * 0.5, font.get_ascent(NUMBER_FONT_SIZE) - text_size.y * 0.5)
		dial.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, NUMBER_COLOR)


# ============================================================ PONTEIROS
func _on_sun_pressed() -> void:
	if _solved or _closing:
		return
	_sun = (_sun + 1) % STEPS
	_turn(_sun_hand, _sun)
	_check_answer()


func _on_moon_pressed() -> void:
	if _solved or _closing:
		return
	_moon = (_moon + 1) % STEPS
	_turn(_moon_hand, _moon)
	_check_answer()


func _turn(hand: TextureRect, step: int) -> void:
	# Cliques rápidos: o giro novo substitui o que ainda estava rodando.
	if _hand_tweens.has(hand) and _hand_tweens[hand].is_valid():
		_hand_tweens[hand].kill()
	hand.rotation = fmod(hand.rotation, TAU)
	var target := TAU * step / STEPS
	# Do 11 para o 12 o ponteiro segue em frente em vez de voltar a volta toda.
	if target < hand.rotation:
		target += TAU
	var tw := create_tween()
	_hand_tweens[hand] = tw
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(hand, "rotation", target, 0.22)
	tw.tween_callback(func() -> void: hand.rotation = fmod(hand.rotation, TAU))


func _show_hands() -> void:
	_sun_hand.rotation = TAU * _sun / STEPS
	_moon_hand.rotation = TAU * _moon / STEPS


func _check_answer() -> void:
	if _sun != SUN_TARGET or _moon != MOON_TARGET:
		return
	_solved = true
	_give_music_box()
	# Pequena pausa para o jogador ver os ponteiros no lugar antes de sair.
	await get_tree().create_timer(0.45).timeout
	await close()
	solved.emit()


func _give_music_box() -> void:
	if GameState.has_flag("suitcase_open"):
		return
	GameState.remove_item("suitcase")
	GameState.add_item("music_box")
	GameState.set_flag("suitcase_open", true)
	GameState.set_flag("picked_music_box", true)
	GameState.clear_selection()
	GameState.save_game()


# ============================================================ ABRIR / FECHAR
# O game.gd chama open() e close(). Esc também chama close().
func open() -> void:
	if visible or GameState.has_flag("suitcase_open"):
		return
	_closing = false
	_solved = false
	visible = true
	# Os ponteiros ficam onde o jogador deixou da última vez.
	_show_hands()
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
# Os relógios são filhos do Background, então acompanham o zoom.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2.ONE, time)
