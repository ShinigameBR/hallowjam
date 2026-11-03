extends Control
## Zoom no buraco da areia do cais.
## Antes de cavar: só a areia fechada e o buraco clicável.
## Um clique cava (flag "dirt_dug"): a imagem vira o buraco aberto, o fundo do
## cais também muda, e a maleta e a minhoca aparecem para pegar.
## O buraco fica cavado para sempre; itens não pegos continuam lá esperando.
##
## Sai com Esc, botão direito ou game.gd chamando close().

signal closed

const HOLE_IMG := preload("res://assets/backgrounds/zoom_buraco_fechado.png")
const HOLE_DUG_IMG := preload("res://assets/backgrounds/zoom_buraco_cavado.png")

## Flag do buraco cavado (o fundo do cais usa a mesma).
const DUG_FLAG := "dirt_dug"
## Flags iguais às do ItemPickup ("picked_<item_id>"), para o resto do jogo entender.
const SUITCASE_FLAG := "picked_suitcase"
const BAIT_FLAG := "picked_bait"
## Folga (em pixels da PNG) em volta do desenho dos itens para o clique.
const ITEM_CLICK_MARGIN := 6

@onready var _background: TextureRect = $Background
@onready var _hole: Button = $Background/Hole
@onready var _suitcase: TextureButton = $Background/Suitcase
@onready var _bait: TextureButton = $Background/Bait

var _closing := false


func _ready() -> void:
	theme = UI.theme
	visible = false
	_hole.pressed.connect(_dig)
	_suitcase.pressed.connect(_take_suitcase)
	_bait.pressed.connect(_take_bait)
	_build_click_mask(_suitcase, ITEM_CLICK_MARGIN)
	_build_click_mask(_bait, ITEM_CLICK_MARGIN)
	GameState.flags_changed.connect(_refresh)
	_refresh()


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


# A imagem e os itens sempre seguem as flags: cavado fica cavado,
# e só aparece o que ainda não foi pego.
func _refresh() -> void:
	var dug := GameState.has_flag(DUG_FLAG)
	_background.texture = HOLE_DUG_IMG if dug else HOLE_IMG
	_hole.visible = not dug
	_suitcase.visible = dug and not GameState.has_flag(SUITCASE_FLAG)
	_bait.visible = dug and not GameState.has_flag(BAIT_FLAG)


# ============================================================ CAVAR
func _dig() -> void:
	if _closing or GameState.has_flag(DUG_FLAG):
		return
	GameState.set_flag(DUG_FLAG, true)
	GameState.clear_selection()
	GameState.save_game()
	_refresh()
	_zoom(1.04, 0.25)   # "tranco" da areia saindo
	GameState.say("Você cava a areia molhada. No fundo do buraco, uma maleta de couro e uma minhoca gorda.")


# ============================================================ ITENS
func _take_suitcase() -> void:
	_take("suitcase", SUITCASE_FLAG, "Uma maleta de couro, pesada e trancada.")


func _take_bait() -> void:
	_take("bait", BAIT_FLAG, "Uma minhoca gorda, ainda se contorcendo. Serve de isca.")


func _take(item_id: String, flag: String, text: String) -> void:
	# Só com o buraco cavado, e evita pegar duas vezes com cliques rápidos.
	if _closing or not GameState.has_flag(DUG_FLAG) or GameState.has_flag(flag):
		return
	GameState.add_item(item_id)
	GameState.set_flag(flag, true)
	GameState.clear_selection()
	GameState.save_game()
	_refresh()
	GameState.say(text)


# ============================================================ ABRIR / FECHAR
# O game.gd chama open() e close(). Esc também chama close().
func open() -> void:
	if visible:
		return
	_closing = false
	visible = true
	_refresh()
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
# O buraco e os itens são filhos do Background, então acompanham o zoom.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2.ONE, time)
