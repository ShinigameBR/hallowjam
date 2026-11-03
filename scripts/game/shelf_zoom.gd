extends Control
## Zoom no canto da estante: só a imagem e o canto clicável.
## Cada clique no canto abre ou fecha a tábua solta, quantas vezes o jogador
## quiser. Com a tábua aberta, a chave aparece e pode ser pega.
##
## Ao sair (Esc, botão direito ou game.gd chamando close()), se a tábua
## estiver aberta ela fecha primeiro, e só depois o zoom some.

signal closed

const SHELF_IMG := preload("res://assets/backgrounds/zoom_canto_estante_fechado.png")
const SHELF_OPEN_IMG := preload("res://assets/backgrounds/zoom_canto_estante_aberto.png")

## Flag igual à do ItemPickup ("picked_<item_id>"), para o resto do jogo entender.
const PICKUP_FLAG := "picked_key"
## Tempo que o canto fica fechado na tela antes do zoom sumir.
const CLOSE_BOARD_DELAY := 0.25
## Folga (em pixels da PNG) em volta do desenho da chave para o clique.
const KEY_CLICK_MARGIN := 6
## Áreas clicáveis da tábua, em fração da tela (medidas nas duas PNGs).
const BOARD_CLOSED_RECT := Rect2(0.279, 0.398, 0.142, 0.407)
const BOARD_OPEN_RECT := Rect2(0.092, 0.713, 0.217, 0.287)

@onready var _background: TextureRect = $Background
@onready var _corner: Button = $Background/Corner
@onready var _key: TextureButton = $Background/Key

var _board_open := false
var _closing := false


func _ready() -> void:
	theme = UI.theme
	visible = false
	_corner.pressed.connect(_toggle_board)
	_key.pressed.connect(_take_key)
	_build_click_mask(_key, KEY_CLICK_MARGIN)
	GameState.flags_changed.connect(_refresh_key)
	_refresh_key()


# O clique só vale em cima do desenho (pixels não transparentes da PNG),
# com uma folga para não ficar difícil acertar a parte fina.
func _build_click_mask(button: TextureButton, margin: int) -> void:
	if button.texture_normal == null:
		return
	var image := button.texture_normal.get_image()
	var mask := BitMap.new()
	mask.create_from_image_alpha(image)
	mask.grow_mask(margin, Rect2i(Vector2i.ZERO, image.get_size()))
	button.texture_click_mask = mask


# ============================================================ TÁBUA
func _toggle_board() -> void:
	if _closing:
		return
	_set_board_open(not _board_open)
	_zoom(1.02, 0.18)   # pequeno "tranco" da madeira


func _set_board_open(value: bool) -> void:
	_board_open = value
	_background.texture = SHELF_OPEN_IMG if value else SHELF_IMG
	# A tábua muda de lugar: o clique acompanha o desenho.
	_place_corner(BOARD_OPEN_RECT if value else BOARD_CLOSED_RECT)
	_refresh_key()


func _place_corner(rect: Rect2) -> void:
	_corner.anchor_left = rect.position.x
	_corner.anchor_top = rect.position.y
	_corner.anchor_right = rect.end.x
	_corner.anchor_bottom = rect.end.y
	_corner.offset_left = 0.0
	_corner.offset_top = 0.0
	_corner.offset_right = 0.0
	_corner.offset_bottom = 0.0


# ============================================================ CHAVE
func _refresh_key() -> void:
	_key.visible = _board_open and not GameState.has_flag(PICKUP_FLAG)


func _take_key() -> void:
	# Só com a tábua aberta, e evita pegar duas vezes com cliques rápidos.
	if not _board_open or _closing or GameState.has_flag(PICKUP_FLAG):
		return
	GameState.add_item("key")
	GameState.set_flag(PICKUP_FLAG, true)
	GameState.clear_selection()
	GameState.save_game()
	_key.visible = false
	GameState.say("Atrás da tábua solta, uma chave enferrujada esperava por uma mão.")


# ============================================================ ABRIR / FECHAR
# O game.gd chama open() e close(). Esc também chama close().
func open() -> void:
	if visible:
		return
	_closing = false
	visible = true
	# Sempre começa com o canto fechado.
	_set_board_open(false)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	_zoom(1.15, 0.7)   # a "aproximação" da câmera


func close() -> void:
	if not visible or _closing:
		return
	_closing = true
	# Se a tábua ficou aberta, fecha antes de sair: parece que o jogador fechou.
	if _board_open:
		_set_board_open(false)
		_zoom(1.02, 0.18)
		await get_tree().create_timer(CLOSE_BOARD_DELAY).timeout
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
# O canto e a chave são filhas do Background, então acompanham o zoom.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2.ONE, time)
