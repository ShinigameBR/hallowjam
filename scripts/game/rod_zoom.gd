extends Control
## Zoom na vara de pescar do cais.
## Primeiro a vara está recolhida, com uma ostra presa no anzol para pegar.
## Sem a ostra, o anzol fica livre: selecionar a minhoca no inventário do HUD
## (o zoom fica abaixo dele, como uma sala) e clicar no anzol prende a isca e
## lança a linha (flag "rod_cast"). A imagem vira a vara esticada e um peixe
## aparece na ponta da linha para pegar ("fish_caught").
## A vara fica esticada para sempre; o peixe não pego continua lá esperando.
##
## Sai com Esc, botão direito ou game.gd chamando close().

signal closed

const ROD_IMG := preload("res://assets/backgrounds/zoom_vara_recolhida.jpeg")
const ROD_CAST_IMG := preload("res://assets/backgrounds/zoom_vara_esticada.jpeg")

## Flags iguais às do ItemPickup ("picked_<item_id>"), para o resto do jogo entender.
const OYSTER_FLAG := "picked_oyster"
## Flag da linha lançada (a isca já foi usada).
const CAST_FLAG := "rod_cast"
## Flag do peixe pego (o objetivo e o Carmesim usam a mesma).
const FISH_FLAG := "fish_caught"
## Folga (em pixels da PNG) em volta do desenho dos itens para o clique.
const ITEM_CLICK_MARGIN := 6

@onready var _background: TextureRect = $Background
@onready var _hook: Button = $Background/Hook
@onready var _oyster: TextureButton = $Background/Oyster
@onready var _fish: TextureButton = $Background/Fish

var _closing := false
## Enquanto a animação de lançar roda, o _refresh não mexe na imagem.
var _casting := false


func _ready() -> void:
	theme = UI.theme
	visible = false
	_hook.pressed.connect(_use_hook)
	_oyster.pressed.connect(_take_oyster)
	_fish.pressed.connect(_take_fish)
	_build_click_mask(_oyster, ITEM_CLICK_MARGIN)
	_build_click_mask(_fish, ITEM_CLICK_MARGIN)
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


# A imagem e os itens sempre seguem as flags: lançada fica lançada,
# e só aparece o que ainda não foi pego.
func _refresh() -> void:
	if _casting:
		return
	var cast := _is_cast()
	_background.texture = ROD_CAST_IMG if cast else ROD_IMG
	_hook.visible = not cast
	_oyster.visible = not cast and not GameState.has_flag(OYSTER_FLAG)
	_fish.visible = cast and not GameState.has_flag(FISH_FLAG)


# Saves de antes do zoom da vara só têm "fish_caught": a linha já foi lançada.
func _is_cast() -> bool:
	return GameState.has_flag(CAST_FLAG) or GameState.has_flag(FISH_FLAG)


# ============================================================ ITENS
func _take_oyster() -> void:
	if _closing or _casting or GameState.has_flag(OYSTER_FLAG):
		return
	GameState.add_item("oyster")
	GameState.set_flag(OYSTER_FLAG, true)
	GameState.clear_selection()
	GameState.save_game()
	_refresh()
	GameState.say("Você solta a ostra do anzol. A concha está bem fechada.")


func _take_fish() -> void:
	if _closing or _casting or not _is_cast() or GameState.has_flag(FISH_FLAG):
		return
	GameState.add_item("fish")
	GameState.set_flag(FISH_FLAG, true)
	GameState.clear_selection()
	GameState.save_game()
	_refresh()
	GameState.say("Você tira o peixe do anzol. Ainda se debate.")


# ============================================================ ISCA
# A minhoca precisa estar selecionada no inventário do HUD.
func _use_hook() -> void:
	if _closing or _casting or _is_cast():
		return
	var selected := GameState.selected_item
	if not GameState.has_flag(OYSTER_FLAG):
		GameState.say("Tem uma ostra presa no anzol. Tire ela antes.")
	elif selected == "bait":
		_cast()
	elif selected != "":
		GameState.say("Isso não serve de isca.")
	else:
		GameState.say("O anzol está vazio. Falta uma isca.")


func _cast() -> void:
	_casting = true
	GameState.remove_item("bait")
	GameState.set_flag(CAST_FLAG, true)
	GameState.clear_selection()
	GameState.save_game()

	# Puxa a vara para trás, solta a linha e a câmera "treme" com o arremesso.
	_background.pivot_offset = _background.size * 0.5
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2(1.05, 1.05), 0.22)
	tw.tween_callback(func() -> void: _background.texture = ROD_CAST_IMG)
	tw.tween_property(_background, "scale", Vector2.ONE, 0.3)
	tw.tween_interval(0.5)
	await tw.finished

	_casting = false
	_refresh()
	_pop_fish()
	GameState.say("Você prende a minhoca no anzol e lança a linha. Quase na hora, algo morde e puxa forte.")


# O peixe sobe da água até a ponta da linha.
func _pop_fish() -> void:
	if not _fish.visible:
		return
	var rest := _fish.position
	_fish.pivot_offset = _fish.size * 0.5
	_fish.position.y = rest.y + 80.0
	_fish.modulate.a = 0.0
	_fish.scale = Vector2(0.8, 0.8)
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_fish, "position:y", rest.y, 0.45)
	tw.tween_property(_fish, "scale", Vector2.ONE, 0.45)
	tw.tween_property(_fish, "modulate:a", 1.0, 0.2)


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
	if not visible or _closing or _casting:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	await tw.finished
	visible = false
	_closing = false
	closed.emit()


# Botão direito solta o item selecionado; sem item, fecha o zoom.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		accept_event()
		if GameState.selected_item != "":
			GameState.clear_selection()
		else:
			close()


# Começa a imagem maior e encolhe até o normal: parece a câmera chegando.
# O anzol e os itens são filhos do Background, então acompanham o zoom.
func _zoom(from_scale: float, time: float) -> void:
	await get_tree().process_frame
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2(from_scale, from_scale)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_background, "scale", Vector2.ONE, time)
