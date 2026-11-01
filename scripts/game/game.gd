extends Control
## Vertical-slice controller: rooms, hotspots, inventory use, the ritual and
## every panel in between. All persistent state lives in GameState.

const HOTSPOT := preload("res://scripts/game/hotspot.gd")
const INVENTORY_BAR := preload("res://scripts/game/inventory_bar.gd")
const DIALOG_BOX := preload("res://scripts/game/dialog_box.gd")
const BOOK_PANEL := preload("res://scripts/game/book_panel.gd")
const CIRCLE_PANEL := preload("res://scripts/game/circle_panel.gd")
const KEYPAD_PANEL := preload("res://scripts/game/keypad_panel.gd")
const DIARY_PANEL := preload("res://scripts/game/diary_panel.gd")
const MONSTER_RESULT_PANEL := preload("res://scripts/game/monster_result_panel.gd")
const PAUSE_MENU := preload("res://scripts/game/pause_menu.gd")
const WIN_PANEL := preload("res://scripts/game/win_panel.gd")

const ROOM_NAMES := {
	"main": "SALA PRINCIPAL",
	"kitchen": "COZINHA",
	"basement": "PORÃO",
	"outside": "CAIS",
}

var _backdrop: Control
var _hotspot_layer: Control
var _inventory_bar: HBoxContainer
var _room_label: Label
var _objective_label: Label
var _selection_label: Label
var _dialog: Control
var _book: Control
var _circle: Control
var _keypad: Control
var _diary: Control
var _monster_result: Control
var _pause: Control
var _win: Control
var _fade: ColorRect
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

var _current_overlay: Control
var _hotspots: Array = []
var _changing_room := false
var _resolving_summon := false
var _save_clock := 0.0


func _ready() -> void:
	theme = UI.theme
	if not GameState.run_started:
		GameState.start_new_game()

	_backdrop = $RoomBackdrop
	_build_hotspot_layer()
	_build_hud()
	_build_toast()
	_build_fade()
	_build_overlays()
	_build_dialog()
	_build_pause()
	_build_win()
	_connect_signals()

	_apply_room(GameState.current_room)
	_refresh_objective()
	_update_selection_hint()

	await get_tree().process_frame
	_maybe_intro()


func _process(delta: float) -> void:
	if _win and _win.visible:
		return
	GameState.play_time += delta
	_save_clock += delta
	if _save_clock >= 20.0:
		_save_clock = 0.0
		GameState.save_game()


# ================================================================== BUILD UI
func _build_hotspot_layer() -> void:
	_hotspot_layer = Control.new()
	_hotspot_layer.name = "Hotspots"
	_hotspot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hotspot_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_hotspot_layer)


func _build_hud() -> void:
	var top := PanelContainer.new()
	top.theme_type_variation = "HudPanel"
	top.anchor_right = 1.0
	top.offset_bottom = 70.0
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(top)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.add_theme_constant_override("margin_top", 8)
	top_margin.add_theme_constant_override("margin_bottom", 8)
	top.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top_margin.add_child(top_row)

	var title_box := VBoxContainer.new()
	title_box.custom_minimum_size = Vector2(190, 0)
	title_box.add_theme_constant_override("separation", 0)
	top_row.add_child(title_box)
	title_box.add_child(UI.label("CÍRCULO", "Eyebrow"))
	_room_label = UI.label("SALA PRINCIPAL", "H3")
	title_box.add_child(_room_label)

	_objective_label = UI.label(GameState.objective, "Muted")
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_objective_label)

	var book_button := UI.button("LIVRO", "GhostButton")
	book_button.custom_minimum_size = Vector2(92, 34)
	book_button.pressed.connect(func() -> void: _open_overlay(_book))
	top_row.add_child(book_button)

	var menu_button := UI.button("MENU", "IconButton")
	menu_button.custom_minimum_size = Vector2(76, 34)
	menu_button.pressed.connect(_open_pause)
	top_row.add_child(menu_button)

	var bottom := PanelContainer.new()
	bottom.theme_type_variation = "HudPanel"
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.anchor_right = 1.0
	bottom.offset_top = -110.0
	bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bottom)

	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 20)
	bottom_margin.add_theme_constant_override("margin_right", 20)
	bottom_margin.add_theme_constant_override("margin_top", 12)
	bottom_margin.add_theme_constant_override("margin_bottom", 12)
	bottom.add_child(bottom_margin)

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 18)
	bottom_margin.add_child(bottom_row)

	var selection_box := VBoxContainer.new()
	selection_box.custom_minimum_size = Vector2(210, 0)
	selection_box.add_theme_constant_override("separation", 2)
	selection_box.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_child(selection_box)
	selection_box.add_child(UI.label("INVENTÁRIO", "Eyebrow"))
	_selection_label = UI.label("Nenhum item selecionado.", "Small")
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_box.add_child(_selection_label)

	_inventory_bar = INVENTORY_BAR.new()
	_inventory_bar.auto_select = false
	_inventory_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_inventory_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_bar.item_clicked.connect(_on_item_clicked)
	bottom_row.add_child(_inventory_bar)

	var hint := UI.label("Botão direito\nsolta o item.", "Tiny")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_row.add_child(hint)


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.theme_type_variation = "HudPanel"
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.offset_left = -230.0
	_toast_panel.offset_right = 230.0
	_toast_panel.offset_top = 84.0
	_toast_panel.offset_bottom = 124.0
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.modulate.a = 0.0
	_toast_panel.visible = false
	add_child(_toast_panel)

	_toast_label = UI.label("", "Small")
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_panel.add_child(_toast_label)


func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = UI.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


func _build_overlays() -> void:
	_book = BOOK_PANEL.new()
	add_child(_book)
	_book.closed.connect(func() -> void:
		_clear_overlay(_book)
		_refresh_objective()
	)

	_circle = CIRCLE_PANEL.new()
	add_child(_circle)
	_circle.summon_requested.connect(_on_summon_requested)
	_circle.closed.connect(func() -> void: _clear_overlay(_circle))

	_keypad = KEYPAD_PANEL.new()
	add_child(_keypad)
	_keypad.solved.connect(_on_safe_solved)
	_keypad.closed.connect(func() -> void: _clear_overlay(_keypad))

	_diary = DIARY_PANEL.new()
	add_child(_diary)
	_diary.closed.connect(func() -> void:
		_clear_overlay(_diary)
		_refresh_objective()
	)

	_monster_result = MONSTER_RESULT_PANEL.new()
	add_child(_monster_result)
	_monster_result.finished.connect(_on_monster_result_finished)
	_monster_result.closed.connect(func() -> void: _clear_overlay(_monster_result))


func _build_dialog() -> void:
	_dialog = DIALOG_BOX.new()
	add_child(_dialog)


func _build_pause() -> void:
	_pause = PAUSE_MENU.new()
	add_child(_pause)
	_pause.resume_requested.connect(func() -> void: _pause.close())
	_pause.menu_requested.connect(_go_menu)
	_pause.closed.connect(func() -> void: _clear_overlay(_pause))


func _build_win() -> void:
	_win = WIN_PANEL.new()
	add_child(_win)
	_win.menu_requested.connect(_go_menu)
	_win.restart_requested.connect(_restart)


func _connect_signals() -> void:
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.toast.connect(_show_toast)
	GameState.selection_changed.connect(_on_selection_changed)


# ================================================================== ROOMS
func _apply_room(room_id: String) -> void:
	_backdrop.set_room(room_id)
	if _room_label:
		_room_label.text = String(ROOM_NAMES.get(room_id, room_id.to_upper()))
	_rebuild_hotspots()
	_refresh_objective()


func _change_room(room_id: String) -> void:
	if _changing_room or room_id == GameState.current_room:
		return
	_changing_room = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 0.9, 0.16)
	await out.finished

	GameState.current_room = room_id
	GameState.save_game()
	_apply_room(room_id)

	var fade_in := create_tween()
	fade_in.tween_property(_fade, "modulate:a", 0.0, 0.22)
	await fade_in.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_changing_room = false


func _rebuild_hotspots() -> void:
	for node in _hotspots:
		if is_instance_valid(node):
			_hotspot_layer.remove_child(node)
			node.queue_free()
	_hotspots.clear()

	match GameState.current_room:
		"main": _main_hotspots()
		"kitchen": _kitchen_hotspots()
		"basement": _basement_hotspots()
		"outside": _outside_hotspots()


func _add_hotspot(id: String, label: String, rect: Rect2) -> void:
	var node: Control = HOTSPOT.new()
	node.setup(id, label)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
	node.pressed.connect(_on_hotspot)
	node.set_selected_item(GameState.selected_item)
	_hotspot_layer.add_child(node)
	_hotspots.append(node)


func _main_hotspots() -> void:
	_add_hotspot("bookshelf", "Estante de livros", Rect2(0.16, 0.12, 0.22, 0.42))
	_add_hotspot("basement_door", "Porta do porão", Rect2(0.04, 0.19, 0.12, 0.39))
	_add_hotspot("main_door", "Porta da frente", Rect2(0.405, 0.14, 0.19, 0.44))
	_add_hotspot("kitchen_door", "Porta da cozinha", Rect2(0.83, 0.18, 0.13, 0.40))
	_add_hotspot("window", "Janela", Rect2(0.59, 0.19, 0.17, 0.22))
	if not GameState.has_flag("picked_feather"):
		_add_hotspot("feather", "Pena de gaivota", Rect2(0.625, 0.378, 0.07, 0.035))
	_add_hotspot("mirror", "Espelho", Rect2(0.76, 0.21, 0.08, 0.17))
	if not GameState.has_flag("picked_moss"):
		_add_hotspot("moss", "Musgo da parede", Rect2(0.74, 0.395, 0.06, 0.045))
	if not GameState.has_flag("picked_music_box"):
		_add_hotspot("music_box", "Caixa de música", Rect2(0.74, 0.445, 0.07, 0.055))
	if not GameState.has_flag("picked_mushroom"):
		_add_hotspot("mushrooms", "Cogumelos", Rect2(0.19, 0.54, 0.075, 0.06))
	_add_hotspot("circle", "Círculo mágico", Rect2(0.34, 0.60, 0.36, 0.27))
	_add_hotspot("safe", "Cofre", Rect2(0.225, 0.59, 0.11, 0.10))
	if GameState.has_flag("summoned_green"):
		_add_hotspot("companion", "O Errante Verde", Rect2(0.525, 0.43, 0.13, 0.16))


func _kitchen_hotspots() -> void:
	_add_hotspot("kitchen_door", "Voltar à sala", Rect2(0.03, 0.18, 0.13, 0.40))
	_add_hotspot("shelves", "Prateleiras", Rect2(0.33, 0.11, 0.24, 0.15))
	_add_hotspot("stove", "Fogão a lenha", Rect2(0.11, 0.29, 0.19, 0.18))
	_add_hotspot("sink", "Torneira", Rect2(0.59, 0.35, 0.18, 0.10))
	_add_hotspot("kitchen_window", "Janela", Rect2(0.61, 0.14, 0.14, 0.17))
	if not GameState.has_flag("picked_knife"):
		_add_hotspot("knife", "Faca de cozinha", Rect2(0.30, 0.33, 0.05, 0.07))
	if not GameState.has_flag("picked_candle"):
		_add_hotspot("candle", "Vela de sebo", Rect2(0.53, 0.335, 0.05, 0.075))
	if not GameState.has_flag("picked_syringe"):
		_add_hotspot("syringe", "Seringa vazia", Rect2(0.765, 0.38, 0.08, 0.04))
	if not GameState.has_flag("picked_potion"):
		_add_hotspot("potion", "Poção estranha", Rect2(0.82, 0.35, 0.055, 0.06))


func _basement_hotspots() -> void:
	if not GameState.has_flag("basement_lit"):
		_add_hotspot("dark", "Escuridão", Rect2(0.0, 0.17, 1.0, 0.73))
		_add_hotspot("basement_door", "Voltar à sala", Rect2(0.05, 0.18, 0.12, 0.40))
		return

	_add_hotspot("basement_door", "Voltar à sala", Rect2(0.05, 0.18, 0.12, 0.40))
	_add_hotspot("lamp", "Lâmpada", Rect2(0.46, 0.13, 0.08, 0.10))
	if not GameState.has_flag("picked_rod"):
		_add_hotspot("rod", "Vara de pescar", Rect2(0.19, 0.29, 0.09, 0.31))
	_add_hotspot("crates", "Caixas", Rect2(0.28, 0.43, 0.15, 0.14))
	_add_hotspot("creature", "Criatura na jaula", Rect2(0.545, 0.28, 0.25, 0.35))
	_add_hotspot("barrel", "Barril", Rect2(0.815, 0.39, 0.12, 0.21))


func _outside_hotspots() -> void:
	_add_hotspot("outside_door", "Voltar para a cabana", Rect2(0.03, 0.27, 0.12, 0.36))
	_add_hotspot("horizon", "Horizonte", Rect2(0.55, 0.18, 0.35, 0.25))
	_add_hotspot("sea", "Mar", Rect2(0.30, 0.52, 0.68, 0.42))
	if not GameState.has_flag("picked_algae"):
		_add_hotspot("algae", "Alga viscosa", Rect2(0.20, 0.70, 0.09, 0.11))
	if not GameState.has_flag("picked_shell"):
		_add_hotspot("shell", "Concha", Rect2(0.60, 0.77, 0.05, 0.05))
	if not GameState.has_flag("picked_stone"):
		_add_hotspot("stone", "Pedra do cais", Rect2(0.77, 0.74, 0.08, 0.08))
	_add_hotspot("bucket", "Balde", Rect2(0.845, 0.74, 0.07, 0.08))
	if GameState.has_flag("summoned_green"):
		_add_hotspot("companion", "O Errante Verde", Rect2(0.505, 0.47, 0.12, 0.17))


# ================================================================== INPUT
func _on_hotspot(id: String) -> void:
	if _changing_room or _dialog.visible or _current_overlay != null:
		return
	var sel := GameState.selected_item

	match id:
		# ---------------------------------------------------------- main
		"bookshelf":
			if sel != "":
				_nope()
			else:
				_open_overlay(_book)
		"basement_door", "main_door", "kitchen_door", "outside_door":
			_go_through_door(id)
		"window":
			_say("O mar está negro. Nenhum barco, nenhuma luz além da sua.")
		"feather":
			if sel != "":
				_nope()
			else:
				_pickup("feather", "picked_feather", "Uma pena de gaivota presa na umidade da janela. Leve demais para o vento que existe aqui dentro.")
		"mirror":
			_say("O espelho devolve seu rosto com um atraso mínimo. Você decide não olhar duas vezes.")
		"moss":
			if sel != "":
				_nope()
			else:
				_pickup("moss", "picked_moss", "Você raspa um tufo de musgo da parede. Pequenas flores brancas se desfazem entre os dedos.")
		"music_box":
			if sel != "":
				_nope()
			else:
				_pickup("music_box", "picked_music_box", "Uma caixa de música. A corda ainda funciona. A valsa começa sozinha e para.")
		"mushrooms":
			if sel != "":
				_nope()
			else:
				_pickup("mushroom", "picked_mushroom", "Cogumelos pálidos crescem entre as tábuas. Cheiram a terra e a algo doce demais.")
		"circle":
			_open_overlay(_circle)
		"safe":
			if sel != "":
				_say("Não há fechadura para forçar. Há um teclado.")
			elif GameState.has_flag("safe_open"):
				if GameState.has_item("diary"):
					_open_overlay(_diary)
				else:
					_say("O cofre está vazio. Só o diário importava.")
			else:
				_open_overlay(_keypad)
		"companion":
			if GameState.current_room == "outside":
				_finish_game()
			else:
				_say("Ele inclina a cabeça na direção da porta da frente. O cais.")

		# ---------------------------------------------------------- kitchen
		"knife":
			if sel != "":
				_nope()
			else:
				_pickup("knife", "picked_knife", "Uma faca de cozinha, ainda afiada. Serve para cortar ervas, peixes e outras coisas.")
		"candle":
			if sel != "":
				_nope()
			else:
				_pickup("candle", "picked_candle", "Uma vela de sebo. A chama é pequena, mas teimosa.")
		"syringe":
			if sel != "":
				_nope()
			else:
				_pickup("syringe", "picked_syringe", "Uma seringa vazia. Grande o bastante para extrair quase qualquer coisa.")
		"potion":
			if sel == "syringe":
				_combine_tranq_from_counter()
			elif sel != "":
				_nope()
			else:
				_pickup("potion", "picked_potion", "Poção Estranha. O rótulo diz: para dormir. O líquido violeta parece olhar de volta.")
		"shelves":
			if sel != "":
				_nope()
			elif GameState.has_flag("picked_sardines"):
				_say("Latas vazias e um cheiro antigo.")
			else:
				GameState.set_flag("picked_sardines", true)
				GameState.add_item("sardines")
				GameState.save_game()
				_rebuild_hotspots()
				_say("Você encontra uma lata de sardinha enferrujada. Comida é comida.")
		"sink":
			if sel != "" and sel != "syringe":
				_nope()
			elif GameState.has_flag("water_taken"):
				_say("A torneira continua cuspindo água salgada.")
			else:
				GameState.set_flag("water_taken", true)
				GameState.add_item("water")
				GameState.save_game()
				_rebuild_hotspots()
				_say("Você enche uma garrafa quebrada com água do mar.")
		"stove":
			_say("O forno está morno. Alguém cozinhou aqui há pouco tempo.")
		"kitchen_window":
			_say("A cozinha cheira a sal e a gordura antiga.")

		# ---------------------------------------------------------- basement
		"dark":
			if GameState.has_item("candle") or sel == "candle":
				GameState.set_flag("basement_lit", true)
				GameState.clear_selection()
				GameState.save_game()
				_rebuild_hotspots()
				_say("Você acende a vela. A chama revela uma jaula, caixas e um barril.")
			else:
				_say("Está escuro demais. Você precisa de uma luz.")
		"lamp":
			_say("A lâmpada balança sozinha. O porão cheira a ferrugem e a maré baixa.")
		"rod":
			if sel != "":
				_nope()
			else:
				_pickup("rod", "picked_rod", "Uma vara de pescar encostada na parede. A linha ainda tem um anzol.")
		"crates":
			_say("Caixas vazias. Há marcas de unhas na madeira.")
		"barrel":
			if sel == "syringe":
				GameState.replace_item("syringe", "monster_fluid")
				GameState.clear_selection()
				GameState.save_game()
				_say("Você extrai um líquido verde e viscoso do barril. Ele ferve baixinho dentro da seringa.")
			else:
				_say("Um barril de líquido verde. Ferve baixinho quando você se aproxima.")
		"creature":
			_interact_creature(sel)

		# ---------------------------------------------------------- outside
		"sea":
			_fish(sel)
		"algae":
			if sel != "":
				_nope()
			else:
				_pickup("algae", "picked_algae", "Alga viscosa, salgada, viva. Ainda guarda água do mar por dentro.")
		"shell":
			if sel != "":
				_nope()
			else:
				_pickup("shell", "picked_shell", "Uma concha em espiral, dura e vazia. Nenhum outro bicho escolheu morar aqui.")
		"stone":
			if sel != "":
				_nope()
			else:
				_pickup("stone", "picked_stone", "Uma pedra pesada e fria, coberta de limo.")
		"bucket":
			_say("Um balde furado. Só serve para lembrar que alguém esteve aqui.")
		"horizon":
			_say("Nenhum barco no horizonte. Só a maré.")


func _go_through_door(id: String) -> void:
	GameState.clear_selection()
	match id:
		"basement_door":
			if GameState.current_room == "basement":
				_change_room("main")
			else:
				_change_room("basement")
		"main_door":
			_change_room("outside")
		"kitchen_door":
			if GameState.current_room == "kitchen":
				_change_room("main")
			else:
				_change_room("kitchen")
		"outside_door":
			_change_room("main")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		GameState.clear_selection()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		if _win.visible:
			return
		if _pause.visible:
			if _pause.handle_cancel():
				get_viewport().set_input_as_handled()
			return
		if _current_overlay != null:
			if _current_overlay == _monster_result:
				_monster_result.dismiss()
			else:
				_current_overlay.close()
			get_viewport().set_input_as_handled()
			return
		if _dialog.visible:
			_dialog.advance()
			get_viewport().set_input_as_handled()
			return
		_open_pause()
		get_viewport().set_input_as_handled()


func _open_overlay(node: Control) -> void:
	if node == null or _dialog.visible or _changing_room:
		return
	_current_overlay = node
	node.open()


func _clear_overlay(node: Control) -> void:
	if _current_overlay == node:
		_current_overlay = null


func _open_pause() -> void:
	if _dialog.visible or _current_overlay != null:
		return
	_current_overlay = _pause
	_pause.open()


# ================================================================== ITEMS
func _on_item_clicked(id: String) -> void:
	if id == "diary":
		GameState.clear_selection()
		_open_overlay(_diary)
		return
	if GameState.selected_item == "syringe" and id == "potion":
		_combine_tranq()
		return
	GameState.select_item(id)


func _pickup(item_id: String, flag: String, text: String) -> void:
	if GameState.has_flag(flag):
		return
	GameState.add_item(item_id)
	GameState.set_flag(flag)
	GameState.clear_selection()
	GameState.save_game()
	_rebuild_hotspots()
	_refresh_objective()
	_say(text)


func _nope() -> void:
	GameState.notify("Nada acontece.")


func _combine_tranq() -> void:
	if not GameState.has_item("syringe") or not GameState.has_item("potion"):
		return
	GameState.remove_item("potion")
	GameState.replace_item("syringe", "tranq")
	GameState.clear_selection()
	GameState.save_game()
	_say("Você puxa a poção violeta para dentro da seringa. A dose parece... suficiente.")


func _combine_tranq_from_counter() -> void:
	if not GameState.has_item("syringe"):
		return
	GameState.set_flag("picked_potion", true)
	GameState.replace_item("syringe", "tranq")
	GameState.clear_selection()
	GameState.save_game()
	_rebuild_hotspots()
	_say("Você puxa a poção violeta para dentro da seringa. A dose parece... suficiente.")


func _interact_creature(sel: String) -> void:
	var sleepy := GameState.has_flag("creature_tranquilized") or GameState.has_flag("creature_calmed")

	if sel == "tranq":
		if sleepy:
			_say("A criatura já está imóvel.")
			return
		GameState.remove_item("tranq")
		GameState.set_flag("creature_tranquilized", true)
		GameState.clear_selection()
		GameState.save_game()
		_rebuild_hotspots()
		_refresh_objective()
		_say("A agulha entra. A criatura pisca uma vez e desaba contra o fundo da jaula.")
		return

	if sel == "music_box":
		if sleepy:
			_say("A valsa já fez o que tinha de fazer.")
			return
		GameState.set_flag("creature_calmed", true)
		GameState.clear_selection()
		GameState.save_game()
		_rebuild_hotspots()
		_refresh_objective()
		_say("Você dá corda na caixa. A valsa enche o porão. A criatura para de bater na jaula e fecha os olhos.")
		return

	if sel == "knife":
		if not sleepy:
			_say("A criatura arranha a jaula e rosna. Você recua antes que ela alcance seus dedos.")
			return
		if GameState.has_flag("meat_taken"):
			_say("Não sobrou muito. Só o cheiro.")
			return
		GameState.add_item("meat")
		GameState.set_flag("meat_taken", true)
		GameState.clear_selection()
		GameState.save_game()
		_rebuild_hotspots()
		_refresh_objective()
		_say("Você corta um pedaço generoso. A carne ainda está quente. Você prefere não pensar de onde veio.")
		return

	if sel == "syringe":
		if GameState.has_item("monster_fluid"):
			_say("A seringa já está cheia.")
			return
		GameState.replace_item("syringe", "monster_fluid")
		GameState.clear_selection()
		GameState.save_game()
		_say("Você extrai um líquido escuro da criatura. Ela nem abre os olhos.")
		return

	if sleepy and not GameState.has_flag("meat_taken"):
		_say("A criatura está imóvel. A faca está no inventário.")
	elif GameState.has_flag("meat_taken"):
		_say("A jaula cheira a ferro. A criatura respira devagar.")
	else:
		_say("A criatura bate na jaula. Os olhos seguem você pelo escuro.")


func _fish(sel: String) -> void:
	if sel == "rod":
		if GameState.has_flag("fish_caught"):
			_say("O mar já te deu o que tinha.")
			return
		GameState.add_item("fish")
		GameState.set_flag("fish_caught", true)
		GameState.clear_selection()
		GameState.save_game()
		_rebuild_hotspots()
		_say("Você lança a linha. Algo morde. Um peixe prateado debate no cais.")
	elif GameState.has_item("rod"):
		_say("Você precisa segurar a vara. Selecione-a no inventário.")
	else:
		_say("O mar está violento. Sem uma vara, não dá para pescar.")


# ================================================================== RITUAL
func _on_summon_requested() -> void:
	if _resolving_summon:
		return
	_resolving_summon = true
	var ids: Array = GameState.circle.duplicate()
	var result := ItemDB.resolve_summon(ids)
	GameState.track_monster(result)

	if result == ItemDB.TARGET:
		GameState.consume_circle()
		GameState.set_flag("summoned_green", true)
		GameState.save_game()
		_refresh_objective()
	else:
		GameState.save_game()

	await _circle.close()
	_current_overlay = null
	await get_tree().create_timer(0.16).timeout
	_current_overlay = _monster_result
	_monster_result.show_result(result)


func _on_monster_result_finished(victory: bool) -> void:
	_resolving_summon = false
	_current_overlay = null
	if victory:
		_refresh_objective()
		_rebuild_hotspots()
		_say("O Errante Verde inclina a cabeça na direção do cais. O círculo se apaga.")
	else:
		GameState.clear_circle()
		_say("A fumaça se desfaz. As oferendas voltam para as suas mãos.")


func _on_safe_solved() -> void:
	_refresh_objective()
	await get_tree().create_timer(0.22).timeout
	_say("O cofre abre com um estalo. Dentro, só um diário. A capa está morna.")


# ================================================================== ENDING
func _finish_game() -> void:
	if _dialog.visible:
		return
	_show_dialog([
		{"speaker": "O ERRANTE VERDE", "text": "Ele se ergue na água e oferece uma mão longa e úmida."},
		{"text": "Você sobe. A cabana encolhe atrás de vocês até virar uma luz pequena."},
		{"text": "O mar abre caminho."},
	])
	await _dialog.finished
	GameState.set_flag("won", true)
	GameState.save_game()
	_refresh_objective()
	_win.show_win()
	GameState.delete_save()


func _go_menu() -> void:
	GameState.save_game()
	SceneTransition.change_scene("res://scenes/main_menu.tscn")


func _restart() -> void:
	GameState.start_new_game()
	SceneTransition.change_scene("res://scenes/game.tscn")


# ================================================================== TEXT
func _maybe_intro() -> void:
	if GameState.has_flag("intro_done"):
		return
	GameState.set_flag("intro_done", true)
	GameState.save_game()
	_show_dialog([
		{"text": "Você acorda com o som do mar batendo nos pilares."},
		{"text": "A cabana pertence a um bruxo. Ele não está aqui. Você não lembra como chegou."},
		{"text": "No chão, um círculo. Nas paredes, um aviso: \"SÓ O QUE NASCE DAS QUALIDADES ATRAVESSA A MARÉ.\""},
		{"speaker": "VOCÊ", "text": "Então eu preciso descobrir o que ele queria invocar."},
	])


func _say(text: String, speaker: String = "") -> void:
	_show_dialog([{"speaker": speaker, "text": text}])


func _show_dialog(lines: Array) -> void:
	if _dialog == null or _dialog.visible:
		return
	_dialog.open(lines)


func _on_objective_changed(text: String) -> void:
	if _objective_label:
		_objective_label.text = text


func _refresh_objective() -> void:
	var text := "Explore a cabana e descubra como escapar."
	if GameState.has_flag("won"):
		text = "Você está livre."
	elif GameState.has_flag("summoned_green"):
		text = "O Errante Verde espera no cais. Vá até ele."
	elif GameState.has_flag("meat_taken"):
		text = "Coloque comida, vento e água no círculo."
	elif GameState.has_flag("creature_tranquilized") or GameState.has_flag("creature_calmed"):
		text = "A criatura está imóvel. Use a faca para pegar carne."
	elif GameState.has_flag("diary_read"):
		text = "Reúna as oferendas: comida, vento e água."
	elif GameState.has_flag("diary_found"):
		text = "Leia o diário no inventário."
	elif GameState.has_flag("safe_open"):
		text = "O cofre está aberto. Pegue o diário."
	elif GameState.has_flag("shelf_seen"):
		text = "O cofre pede quatro números. As cores estão na estante."
	GameState.set_objective(text)


func _on_selection_changed() -> void:
	_update_selection_hint()
	for node in _hotspots:
		if is_instance_valid(node):
			node.set_selected_item(GameState.selected_item)


func _update_selection_hint() -> void:
	if _selection_label == null:
		return
	var selected := GameState.selected_item
	if selected == "":
		_selection_label.text = "Nenhum item selecionado."
	elif selected == "syringe":
		_selection_label.text = "Seringa selecionada. Clique na poção para preparar o tranquilizante."
	else:
		_selection_label.text = "Usando: %s." % ItemDB.item_name(selected)


func _show_toast(text: String) -> void:
	if _toast_panel == null:
		return
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_label.text = text
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.14)
	_toast_tween.tween_interval(1.7)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.finished.connect(func() -> void: _toast_panel.visible = false)
