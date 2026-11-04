extends Control
## Zoom nas gavetas do lado esquerdo: só a imagem e a gaveta clicável.
## Cada clique na gaveta abre ou fecha, quantas vezes o jogador quiser.
## Com a gaveta aberta, a chave de fenda aparece e pode ser pega.
##
## Ao sair (Esc, botão direito ou game.gd chamando close()), se a gaveta
## estiver aberta ela fecha primeiro, e só depois o zoom some.

signal closed

const DRAWERS_IMG := preload("res://assets/backgrounds/gavetas.jpeg")
const DRAWERS_OPEN_IMG := preload("res://assets/backgrounds/gavetas_abertas.jpeg")

## Flag igual à do ItemPickup ("picked_<item_id>"), para o resto do jogo entender.
const PICKUP_FLAG := "picked_screwdriver"
## Tempo que a gaveta fica fechada na tela antes do zoom sumir.
const CLOSE_DRAWER_DELAY := 0.25
## Folga (em pixels da PNG) em volta do desenho da chave de fenda para o clique.
const SCREWDRIVER_CLICK_MARGIN := 6

@onready var _background: TextureRect = $Background
@onready var _left_drawer: Button = $Background/LeftDrawer
@onready var _screwdriver: TextureButton = $Background/Screwdriver

var _drawer_open := false
var _closing := false


func _ready() -> void:
	theme = UI.theme
	visible = false
	_left_drawer.pressed.connect(_toggle_drawer)
	_screwdriver.pressed.connect(_take_screwdriver)
	_build_click_mask(_screwdriver, SCREWDRIVER_CLICK_MARGIN)
	UI.add_close_hint(self)


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


# ============================================================ GAVETA
func _toggle_drawer() -> void:
	if _closing:
		return
	_set_drawer_open(not _drawer_open)
	_zoom(1.02, 0.18)   # pequeno "tranco" da gaveta


func _set_drawer_open(value: bool) -> void:
	_drawer_open = value
	_background.texture = DRAWERS_OPEN_IMG if value else DRAWERS_IMG
	_screwdriver.visible = value and not GameState.has_flag(PICKUP_FLAG)


# ============================================================ CHAVE DE FENDA
func _take_screwdriver() -> void:
	# Só com a gaveta aberta, e evita pegar duas vezes com cliques rápidos.
	if not _drawer_open or _closing or GameState.has_flag(PICKUP_FLAG):
		return
	GameState.add_item("screwdriver")
	GameState.set_flag(PICKUP_FLAG, true)
	GameState.clear_selection()
	GameState.save_game()
	_screwdriver.visible = false
	GameState.say("Uma chave de fenda velha, mas ainda firme. Dá para abrir coisas teimosas.")


# ============================================================ ABRIR / FECHAR
# O game.gd chama open() e close(). Esc também chama close().
func open() -> void:
	if visible:
		return
	_closing = false
	visible = true
	# Sempre começa com a gaveta fechada.
	_set_drawer_open(false)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	_zoom(1.15, 0.7)   # a "aproximação" da câmera


func close() -> void:
	if not visible or _closing:
		return
	_closing = true
	# Se a gaveta ficou aberta, fecha antes de sair: parece que o jogador fechou.
	if _drawer_open:
		_set_drawer_open(false)
		_zoom(1.02, 0.18)
		await get_tree().create_timer(CLOSE_DRAWER_DELAY).timeout
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
# A gaveta e a chave de fenda são filhas do Background, então acompanham o zoom.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2.ONE, time)
