extends Control
## Vertical-slice controller: rooms, hotspots, inventory use, the ritual and
## every panel in between. All persistent state lives in GameState.

const INVENTORY_BAR := preload("res://scripts/game/inventory_bar.gd")
const DIALOG_BOX := preload("res://scripts/game/dialog_box.gd")
const BOOK_PANEL := preload("res://scripts/game/book_panel.gd")
const CIRCLE_PANEL := preload("res://scripts/game/circle_panel.gd")
const SAFE_ZOOM := preload("res://scenes/components/safe_zoom.tscn")
const DRAWERS_ZOOM := preload("res://scenes/components/drawers_zoom.tscn")
const SHELF_ZOOM := preload("res://scenes/components/shelf_zoom.tscn")
const DOOR_HINT := preload("res://scenes/components/door_hint.tscn")
const HOLE_ZOOM := preload("res://scenes/components/hole_zoom.tscn")
const ROD_ZOOM := preload("res://scenes/components/rod_zoom.tscn")
const SUITCASE_ZOOM := preload("res://scenes/components/suitcase_zoom.tscn")
const ATTIC_CHEST_ZOOM := preload("res://scenes/components/attic_chest_zoom.tscn")
const PAGE_ICON := preload("res://assets/props/pagina_do_livro.png")
const DIARY_PANEL := preload("res://scripts/game/diary_panel.gd")
const PAUSE_MENU := preload("res://scripts/game/pause_menu.gd")
const WIN_PANEL := preload("res://scripts/game/win_panel.gd")

const ROOM_NAMES := {
	"main": "SALA PRINCIPAL",
	"main_left": "LADO ESQUERDO",
	"main_right": "LADO DIREITO",
	"attic": "SOTÃO",
	"outside": "CAIS",
}

const INVENTORY_HEIGHT := 150.0
const INVENTORY_TOP_OPEN := -150.0
const INVENTORY_TOP_CLOSED := -110.0

var _room_host: Control
var _inventory_bar: HBoxContainer
var _inventory_panel: PanelContainer
var _inventory_toggle: Button
var _inventory_tween: Tween
var _inventory_open := false
var _room_label: Label
var _objective_label: Label
var _selection_label: Label
var _dialog: Control
var _book: Control
var _book_button: TextureButton
var _book_slot: Control
var _objective_tween: Tween
var _circle: Control
var _safe: Control
var _drawers: Control
var _shelf: Control
var _door_hint: Control
var _hole: Control
var _rod: Control
var _suitcase: Control
var _attic_chest: Control
## Zooms que ficam abaixo do HUD, como uma sala: o inventário continua usável.
var _hud_zooms: Array[Control] = []
var _diary: Control
var _pause: Control
var _win: Control
var _fade: ColorRect
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

var _current_overlay: Control
var _changing_room := false
var _resolving_summon := false
var _attic_cutscene_running := false
var _save_clock := 0.0


func _ready() -> void:
	theme = UI.theme
	Audio.play_music("game")
	if not GameState.run_started:
		GameState.start_new_game()

	_build_room_host()
	_build_hud()
	_build_toast()
	_build_fade()
	RoomManager.register_host(_room_host, _fade)
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
	_maybe_open_attic_door()


func _process(delta: float) -> void:
	if _win and _win.visible:
		return
	GameState.play_time += delta
	_save_clock += delta
	if _save_clock >= 20.0:
		_save_clock = 0.0
		GameState.save_game()


func _exit_tree() -> void:
	var room := RoomManager.current_room_node()
	if room != null and is_instance_valid(room) and is_ancestor_of(room):
		RoomManager.unregister_host()


# ================================================================== BUILD UI
func _build_room_host() -> void:
	_room_host = Control.new()
	_room_host.name = "RoomHost"
	_room_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_room_host.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_room_host)


func _build_hud() -> void:
	_build_room_block()
	_build_top_actions()
	_build_inventory_panel()
	_build_inventory_toggle()


func _build_room_block() -> void:
	var block := VBoxContainer.new()
	block.name = "HudRoomBlock"
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.anchor_top = 0.0
	block.anchor_bottom = 0.0
	block.offset_left = 22.0
	block.offset_top = 16.0
	block.offset_right = 392.0
	block.offset_bottom = 150.0
	block.add_theme_constant_override("separation", 8)
	add_child(block)

	var card := PanelContainer.new()
	card.name = "RoomCard"
	card.theme_type_variation = "HudPanel"
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(card)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 9)
	card.add_child(row)

	var mark := ColorRect.new()
	mark.color = Color(UI.ACCENT, 0.7)
	mark.custom_minimum_size = Vector2(2, 16)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)

	_room_label = UI.label("SALA PRINCIPAL", "H3")
	_room_label.add_theme_font_size_override("font_size", 18)
	_hud_text(_room_label)
	row.add_child(_room_label)

	# Objective as a quiet line under the place name, not a mission card.
	_objective_label = UI.label(GameState.objective, "Objective")
	_hud_text(_objective_label)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size = Vector2(360, 0)
	_objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective_label.add_theme_constant_override("line_spacing", 3)
	block.add_child(_objective_label)


func _build_top_actions() -> void:
	var actions := HBoxContainer.new()
	actions.name = "HudActions"
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.anchor_left = 1.0
	actions.anchor_right = 1.0
	actions.anchor_top = 0.0
	actions.anchor_bottom = 0.0
	actions.offset_left = -260.0
	actions.offset_right = -22.0
	actions.offset_top = 16.0
	actions.offset_bottom = 80.0
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)

	_book_slot = PanelContainer.new()
	_book_slot.theme_type_variation = "HudSlot"
	_book_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_book_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_book_slot.visible = false
	actions.add_child(_book_slot)

	_book_button = TextureButton.new()
	_book_button.name = "BookPageButton"
	_book_button.texture_normal = PAGE_ICON
	_book_button.ignore_texture_size = true
	_book_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_book_button.custom_minimum_size = Vector2(40, 46)
	_book_button.tooltip_text = "Página do livro"
	_book_button.focus_mode = Control.FOCUS_NONE
	_book_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_book_button.visible = false
	_book_button.pressed.connect(func() -> void: _open_book())
	_book_slot.add_child(_book_button)

	var menu_button := UI.button("MENU", "HudButton")
	menu_button.custom_minimum_size = Vector2(94, 50)
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_open_pause)
	actions.add_child(menu_button)


func _build_inventory_panel() -> void:
	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.theme_type_variation = "HudPanel"
	_inventory_panel.anchor_top = 1.0
	_inventory_panel.anchor_bottom = 1.0
	_inventory_panel.anchor_right = 1.0
	_inventory_panel.offset_top = INVENTORY_TOP_CLOSED
	_inventory_panel.offset_bottom = INVENTORY_TOP_CLOSED + INVENTORY_HEIGHT
	# A bandeja em si é só fundo: os slots continuam capturando o clique.
	_inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory_panel.visible = false
	add_child(_inventory_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 216)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_inventory_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)

	_selection_label = UI.label("Nenhum item selecionado.", "Small")
	_hud_text(_selection_label)
	_selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_selection_label)

	var hint := UI.label("Botão direito solta o item.", "Tiny")
	_hud_text(hint)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(hint)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(center)

	_inventory_bar = INVENTORY_BAR.new()
	_inventory_bar.auto_select = false
	_inventory_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_inventory_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory_bar.item_clicked.connect(_on_item_clicked)
	center.add_child(_inventory_bar)


func _build_inventory_toggle() -> void:
	_inventory_toggle = UI.button("INVENTÁRIO", "HudButton")
	_inventory_toggle.name = "InventoryToggle"
	_inventory_toggle.anchor_top = 1.0
	_inventory_toggle.anchor_bottom = 1.0
	_inventory_toggle.offset_left = 22.0
	_inventory_toggle.offset_right = 192.0
	_inventory_toggle.offset_top = -88.0
	_inventory_toggle.offset_bottom = -40.0
	_inventory_toggle.pressed.connect(_toggle_inventory)
	add_child(_inventory_toggle)


func _toggle_inventory() -> void:
	if _inventory_panel == null or _inventory_toggle == null:
		return
	if _inventory_tween and _inventory_tween.is_valid():
		_inventory_tween.kill()
	_inventory_open = not _inventory_open
	_inventory_toggle.text = "FECHAR" if _inventory_open else "INVENTÁRIO"
	_inventory_tween = create_tween().set_parallel(true)
	_inventory_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _inventory_open:
		_inventory_panel.visible = true
		_inventory_panel.modulate.a = 0.0
		_inventory_tween.tween_property(_inventory_panel, "offset_top", INVENTORY_TOP_OPEN, 0.22)
		_inventory_tween.tween_property(_inventory_panel, "offset_bottom", INVENTORY_TOP_OPEN + INVENTORY_HEIGHT, 0.22)
		_inventory_tween.tween_property(_inventory_panel, "modulate:a", 1.0, 0.18)
	else:
		_inventory_tween.tween_property(_inventory_panel, "offset_top", INVENTORY_TOP_CLOSED, 0.2)
		_inventory_tween.tween_property(_inventory_panel, "offset_bottom", INVENTORY_TOP_CLOSED + INVENTORY_HEIGHT, 0.2)
		_inventory_tween.tween_property(_inventory_panel, "modulate:a", 0.0, 0.16)
		_inventory_tween.tween_callback(_hide_inventory_panel).set_delay(0.2)


func _hide_inventory_panel() -> void:
	if _inventory_panel == null or _inventory_open:
		return
	_inventory_panel.visible = false


## Fecha o inventário na hora, sem alternar. Usado quando um diálogo ou uma
## troca de sala precisa da tela livre.
func _close_inventory() -> void:
	if not _inventory_open:
		return
	if _inventory_tween and _inventory_tween.is_valid():
		_inventory_tween.kill()
	_inventory_open = false
	if _inventory_toggle != null:
		_inventory_toggle.text = "INVENTÁRIO"
	if _inventory_panel != null:
		_inventory_panel.visible = false
		_inventory_panel.offset_top = INVENTORY_TOP_CLOSED
		_inventory_panel.offset_bottom = INVENTORY_TOP_CLOSED + INVENTORY_HEIGHT
		_inventory_panel.modulate.a = 0.0


func _hud_text(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.theme_type_variation = "HudPanel"
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.offset_left = -230.0
	_toast_panel.offset_right = 230.0
	_toast_panel.offset_top = 96.0
	_toast_panel.offset_bottom = 136.0
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

	_safe = SAFE_ZOOM.instantiate()
	add_child(_safe)
	_safe.solved.connect(_on_safe_solved)
	_safe.closed.connect(func() -> void: _clear_overlay(_safe))

	_drawers = DRAWERS_ZOOM.instantiate()
	add_child(_drawers)
	_drawers.closed.connect(func() -> void: _clear_overlay(_drawers))

	_shelf = SHELF_ZOOM.instantiate()
	add_child(_shelf)
	_shelf.closed.connect(func() -> void:
		_clear_overlay(_shelf)
		_refresh_objective()
	)

	_door_hint = DOOR_HINT.instantiate()
	add_child(_door_hint)
	_door_hint.closed.connect(func() -> void: _clear_overlay(_door_hint))

	_hole = HOLE_ZOOM.instantiate()
	add_child(_hole)
	_hole.closed.connect(func() -> void:
		_clear_overlay(_hole)
		_refresh_objective()
	)

	_rod = ROD_ZOOM.instantiate()
	_add_hud_zoom(_rod)
	_rod.closed.connect(func() -> void:
		_clear_overlay(_rod)
		_refresh_objective()
	)

	_suitcase = SUITCASE_ZOOM.instantiate()
	add_child(_suitcase)
	_suitcase.solved.connect(_on_suitcase_solved)
	_suitcase.closed.connect(func() -> void: _clear_overlay(_suitcase))

	_attic_chest = ATTIC_CHEST_ZOOM.instantiate()
	add_child(_attic_chest)
	_attic_chest.solved.connect(_on_attic_chest_solved)
	_attic_chest.closed.connect(func() -> void: _clear_overlay(_attic_chest))

	_diary = DIARY_PANEL.new()
	add_child(_diary)
	_diary.closed.connect(func() -> void:
		_clear_overlay(_diary)
		_refresh_objective()
	)


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
	GameState.flags_changed.connect(_on_flags_changed)
	GameState.dialogue_requested.connect(_on_dialogue_requested)
	GameState.panel_requested.connect(_on_panel_requested)
	GameState.action_requested.connect(_on_action)
	GameState.inventory_changed.connect(_refresh_book_button)
	RoomManager.room_changed.connect(_on_room_changed)
	RoomManager.transition_started.connect(_on_transition_started)
	RoomManager.transition_finished.connect(_on_transition_finished)
	_refresh_book_button()


# ================================================================== ROOMS
func _apply_room(room_id: String) -> void:
	_close_inventory()
	var scene := RoomManager.get_room_scene(room_id)
	if scene == null:
		push_warning("No room scene registered for id '%s'." % room_id)
		scene = RoomManager.get_room_scene("main")
	if scene == null:
		return

	RoomManager.load_immediate(scene)
	if _room_label:
		_room_label.text = String(ROOM_NAMES.get(room_id, room_id.to_upper()))
		_room_label.modulate.a = 0.0
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_room_label, "modulate:a", 1.0, 0.3)
	_refresh_objective()


func _change_room(room_id: String) -> void:
	RoomManager.go_to_room(room_id)


func _rebuild_hotspots() -> void:
	var room := RoomManager.current_room_node()
	if room == null or room.get_room_id() != GameState.current_room:
		_apply_room(GameState.current_room)
	else:
		RoomManager.refresh_current()
	_refresh_objective()


# ================================================================== INPUT
func _on_hotspot(id: String) -> void:
	## Compatibility entry point used by tests and optional custom code.
	## Real mouse clicks go straight to the component in the room scene.
	if _changing_room or _dialog.visible or _current_overlay != null:
		return
	var node := RoomManager.find_interactable(id)
	if node != null:
		node.interact()


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
	Audio.play_sfx("page", -2.0)
	_current_overlay = node
	node.open()


func _clear_overlay(node: Control) -> void:
	if _current_overlay != node:
		return
	_current_overlay = null
	# Um painel aberto por cima de um zoom do HUD (ex.: a página do livro)
	# devolve o foco para o zoom que continua aberto embaixo.
	for zoom in _hud_zooms:
		if zoom != node and zoom.visible:
			_current_overlay = zoom


# Coloca o zoom logo acima das salas e abaixo do HUD, para ele receber o mesmo
# inventário, objetivo e botões que as salas.
func _add_hud_zoom(node: Control) -> void:
	add_child(node)
	move_child(node, _room_host.get_index() + 1)
	_hud_zooms.append(node)


func _open_shelf() -> void:
	if _dialog.visible or _changing_room:
		return
	_open_overlay(_shelf)
	if _current_overlay != _shelf:
		return
	if not GameState.has_flag("shelf_seen"):
		GameState.set_flag("shelf_seen", true)
		GameState.save_game()


func _open_book() -> void:
	if _dialog.visible or _changing_room or not GameState.has_item("book_page"):
		return
	_open_overlay(_book)


func _refresh_book_button() -> void:
	if _book_button == null:
		return
	var show_button := GameState.has_item("book_page")
	if show_button and not _book_button.visible:
		_book_button.visible = true
		if _book_slot != null:
			_book_slot.visible = true
		_book_button.pivot_offset = _book_button.custom_minimum_size * 0.5
		_book_button.modulate.a = 0.0
		_book_button.scale = Vector2(0.82, 0.82)
		var tw := create_tween().set_parallel(true)
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_book_button, "modulate:a", 1.0, 0.28)
		tw.tween_property(_book_button, "scale", Vector2.ONE, 0.32)
	else:
		_book_button.visible = show_button
		if _book_slot != null:
			_book_slot.visible = show_button


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
	if id == "suitcase":
		GameState.clear_selection()
		_open_overlay(_suitcase)
		return
	if GameState.selected_item == "screwdriver" and id == "oyster":
		_combine_oyster()
		return
	GameState.select_item(id)


func _combine_oyster() -> void:
	if not GameState.has_item("screwdriver") or not GameState.has_item("oyster"):
		return
	Audio.play_sfx("water", -3.0)
	GameState.remove_item("oyster")
	GameState.add_item("pearl")
	GameState.clear_selection()
	GameState.save_game()
	_say("A chave de fenda força a concha. Dentro, uma pérola lustrosa.")
	_refresh_objective()


# ================================================================== RITUAL
func _on_summon_requested() -> void:
	if _resolving_summon:
		return
	_resolving_summon = true
	var ids: Array = GameState.circle.duplicate()
	var result := ItemDB.resolve_summon(ids)
	GameState.track_monster(result)
	Audio.play_sfx("summon")
	Audio.summon_sfx(result)

	if result == ItemDB.TARGET:
		GameState.consume_circle()
		GameState.set_flag("summoned_carmesim", true)
		GameState.save_game()
	elif result == "branco":
		# A Luz que Escuta não é o Carmesim, mas também atende: a oferenda some
		# e a luz dela passa a iluminar o sótão pelo resto da partida.
		GameState.consume_circle()
		GameState.set_flag("summoned_branco", true)
		GameState.save_game()
	else:
		GameState.save_game()

	await _circle.close()
	_current_overlay = null
	_resolving_summon = false
	await get_tree().create_timer(0.16).timeout

	if result == "azul":
		await _finish_azul_ending()
	elif result == ItemDB.TARGET:
		_refresh_objective()
		_rebuild_hotspots()
		_say("O Carmesim paira sobre o círculo. Ele espera ser alimentado.")
	elif result == "branco":
		_refresh_objective()
		_say("A forma branca dispara para o lado esquerdo da casa. Ela gosta de lugares escuros — siga a luz até o sótão.")
	else:
		GameState.clear_circle()
		_say("A fumaça se desfaz. As oferendas voltam para as suas mãos.")


func _on_safe_solved() -> void:
	_refresh_objective()
	Audio.play_sfx("unlock")
	await get_tree().create_timer(0.22).timeout
	_say("Você tira o rubi do baú e fecha a tampa do cofre. A pedra pulsa, quente, na palma da mão.")


func _on_suitcase_solved() -> void:
	_refresh_objective()
	Audio.play_sfx("unlock")
	await get_tree().create_timer(0.22).timeout
	_say("Os ponteiros se encaixam e a maleta destrava com um clique. Dentro, uma caixa de música: um item raro, de valor sentimental. Algo que contém sentimentos.")


func _on_attic_chest_solved() -> void:
	_refresh_objective()
	Audio.play_sfx("unlock")
	await get_tree().create_timer(0.22).timeout
	_say("Os cinco discos se alinham. A tampa do baú cede, e uma escama azul brilha no fundo.")


# ================================================================== ENDING
func _finish_azul_ending() -> void:
	if _dialog.visible:
		return
	GameState.consume_circle()
	_show_dialog([
		{"speaker": "O CEGO DAS PROFUNDEZAS", "text": "A coisa azul se ergue do círculo. As garras encontram as paredes, o teto, o chão."},
		{"text": "A água sobe pela madeira. O mar entra por baixo da porta e não para de subir."},
		{"text": "Quando o azul cobre tudo, você entende: era para isso que o mar te chamava."},
	])
	await _dialog.finished
	GameState.set_flag("azul_ending", true)
	GameState.set_flag("won", true)
	GameState.save_game()
	_refresh_objective()
	Audio.stop_music(1.2)
	Audio.play_sfx("ending", 2.0)
	_win.show_win()
	GameState.delete_save()


func _go_menu() -> void:
	if GameState.has_flag("won"):
		# Depois do final o save já foi apagado; salvar de novo reativaria
		# CONTINUAR no menu.
		GameState.delete_save()
	else:
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
		{"text": "Numa página solta sobre a estante, está escrito: para abrir a passagem ao sótão, invoque o Carmesim."},
	])


## Depois de alimentado, o Carmesim espera no lado esquerdo e força a porta
## do sótão na primeira vez que o jogador entra lá.
func _maybe_open_attic_door() -> void:
	if _attic_cutscene_running or not _can_open_attic_door():
		return
	_attic_cutscene_running = true
	await get_tree().create_timer(0.4).timeout
	# Espera falas, painéis ou a troca de sala que o jogador abriu nesse meio-tempo.
	while _dialog.visible or _current_overlay != null or _changing_room:
		await get_tree().process_frame
	if not _can_open_attic_door():
		_attic_cutscene_running = false
		return
	_show_dialog([
		{"text": "O Carmesim chegou antes de você. Ele crava os chifres na porta do sótão e força a madeira."},
	])
	await _dialog.finished
	GameState.set_flag("attic_door_open", true)
	GameState.save_game()
	Audio.play_sfx("wood", 1.0)
	Audio.play_sfx("door", -4.0)
	_say("Um estalo seco, e a porta cede. O Carmesim se afasta e olha para você, satisfeito: o caminho está livre.")
	_attic_cutscene_running = false


func _can_open_attic_door() -> bool:
	return GameState.current_room == "main_left" 		and GameState.has_flag("carmesim_fed") 		and not GameState.has_flag("attic_door_open")


func _say(text: String, speaker: String = "") -> void:
	_show_dialog([{"speaker": speaker, "text": text}])


func _show_dialog(lines: Array) -> void:
	_close_inventory()
	if _dialog == null or _dialog.visible:
		return
	_dialog.open(lines)


# ================================================================== ROOM SIGNALS
func _on_room_changed(room: Room) -> void:
	if _room_label == null:
		return
	if room != null:
		var display := room.get_display_name()
		if display == "":
			display = String(ROOM_NAMES.get(room.get_room_id(), room.get_room_id().to_upper()))
		_room_label.text = display
	else:
		_room_label.text = String(ROOM_NAMES.get(GameState.current_room, GameState.current_room.to_upper()))
	_refresh_objective()


func _on_transition_started() -> void:
	_changing_room = true
	_close_inventory()
	Audio.play_sfx("door")


func _on_transition_finished() -> void:
	_changing_room = false
	_maybe_open_attic_door()


func _on_flags_changed() -> void:
	_refresh_objective()


func _on_dialogue_requested(lines: Array) -> void:
	_show_dialog(lines)


func _on_panel_requested(panel_id: String) -> void:
	match panel_id:
		"book":
			_open_book()
		"shelf":
			_open_shelf()
		"circle":
			_open_overlay(_circle)
		"safe":
			_open_overlay(_safe)
		"drawers":
			_open_overlay(_drawers)
		"door_hint":
			_open_overlay(_door_hint)
		"hole":
			_open_overlay(_hole)
		"rod":
			_open_overlay(_rod)
		"suitcase":
			_open_overlay(_suitcase)
		"attic_chest":
			_open_overlay(_attic_chest)
		"diary":
			_open_overlay(_diary)
		_:
			push_warning("Unknown panel id '%s'." % panel_id)


## Actions that are too specific to express with a single inspector field.
## Everything else lives in the component scripts.
func _on_action(action_id: String, _source: Node = null) -> void:
	match action_id:
		"safe":
			_action_safe()
		"sea":
			_action_sea()
		_:
			push_warning("Unknown action id '%s'." % action_id)


func _action_safe() -> void:
	# Depois de aberto, qualquer clique (com ou sem item) dá a mesma resposta.
	if GameState.has_flag("safe_open"):
		_say("O cofre já foi aberto. Não há mais nada para fazer aqui.")
	elif GameState.selected_item != "":
		_say("Não há fechadura para forçar. Só os números coloridos do baú.")
	else:
		_open_overlay(_safe)


func _action_sea() -> void:
	if GameState.has_flag("rod_cast") or GameState.has_flag("fish_caught"):
		_say("O mar já te deu o que tinha.")
	else:
		_say("O mar está violento. A vara de pescar do cais pode tirar algo dele.")


func _on_objective_changed(text: String) -> void:
	if _objective_label == null:
		return
	_objective_label.text = text
	if _objective_tween and _objective_tween.is_valid():
		_objective_tween.kill()
	_objective_label.modulate.a = 0.35
	_objective_tween = create_tween()
	_objective_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_objective_tween.tween_property(_objective_label, "modulate:a", 1.0, 0.28)


func _refresh_objective() -> void:
	var text := "Uma página solta repousa sobre a estante."
	if GameState.has_flag("azul_ending"):
		text = "O mar te levou."
	elif GameState.has_flag("won"):
		text = "Você está livre."
	elif GameState.has_flag("picked_escama_azul"):
		text = "A escama azul está com você."
	elif GameState.has_flag("attic_chest_open"):
		text = "A escama azul brilha dentro do baú."
	elif GameState.has_flag("carmesim_fed") and GameState.has_flag("summoned_branco"):
		text = "O sótão está iluminado."
	elif GameState.current_room == "attic":
		text = "O sótão guarda o resto da história."
	elif GameState.has_flag("attic_door_open"):
		text = "A porta do sótão está aberta."
	elif GameState.has_flag("carmesim_fed"):
		text = "O Carmesim seguiu para o lado esquerdo da casa."
	elif GameState.has_flag("summoned_carmesim"):
		if GameState.has_flag("fish_caught"):
			text = "O Carmesim ainda espera o peixe."
		elif not GameState.has_flag("front_door_open"):
			if not GameState.has_flag("picked_key"):
				text = "A porta não cede. Algo range perto da estante."
			else:
				text = "A chave na porta da frente."
		elif not GameState.has_flag("picked_oyster"):
			text = "Algo pende da vara de pescar do cais."
		elif not GameState.has_flag("rod_cast") and not GameState.has_flag("dirt_dug"):
			text = "A areia do cais esconde um buraco."
		elif not GameState.has_flag("rod_cast") and not GameState.has_item("bait"):
			text = "Algo se contorce no fundo do buraco."
		elif not GameState.has_flag("rod_cast"):
			text = "A vara de pescar espera uma isca."
		else:
			text = "Algo fisgou a linha da vara."
	elif GameState.has_flag("summoned_branco"):
		text = "A luz correu para o lado esquerdo da casa."
	elif not GameState.has_item("book_page"):
		text = "Uma página solta repousa sobre a estante."
	elif not GameState.has_flag("book_read"):
		text = "A página ainda está fechada."
	elif not GameState.has_flag("lavender_revived"):
		text = "A lavanda murcha pede a poção."
	elif not GameState.has_flag("picked_lavender_revived"):
		text = "A lavanda reviveu."
	elif not GameState.has_flag("ruby_taken"):
		text = "O cofre da estante está trancado."
	else:
		text = "O círculo aguarda a lavanda e o rubi."
	GameState.set_objective(text)


func _on_selection_changed() -> void:
	_update_selection_hint()


func _update_selection_hint() -> void:
	if _selection_label == null:
		return
	var selected := GameState.selected_item
	if selected == "":
		_selection_label.text = "Nenhum item selecionado."
	elif selected == "screwdriver":
		_selection_label.text = "Chave de fenda selecionada. Clique na ostra no inventário para abri-la."
	elif selected == "potion":
		_selection_label.text = "Poção selecionada. Use na lavanda murcha, no lado direito."
	elif selected == "bucket":
		_selection_label.text = "Balde selecionado. Encha no mar."
	elif selected == "bucket_water":
		_selection_label.text = "Balde com água selecionado. Use na lareira."
	elif selected == "bait":
		_selection_label.text = "Isca selecionada. Prenda no anzol da vara, no cais."
	elif selected == "fish":
		_selection_label.text = "Peixe selecionado. Ofereça ao Carmesim."
	elif selected == "ruby" or selected == "lavender_revived":
		_selection_label.text = "Usando: %s. Coloque no círculo." % ItemDB.item_name(selected)
	else:
		_selection_label.text = "Usando: %s." % ItemDB.item_name(selected)


func _show_toast(text: String, large: bool = false) -> void:
	if _toast_panel == null:
		return
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_label.text = text
	_toast_label.add_theme_font_size_override("font_size", 16 if large else 12)
	_toast_label.add_theme_color_override("font_color", UI.TEXT if large else UI.MUTED)
	var half_width := 280.0 if large else 230.0
	_toast_panel.offset_left = -half_width
	_toast_panel.offset_right = half_width
	_toast_panel.offset_top = 88.0 if large else 96.0
	_toast_panel.offset_bottom = 156.0 if large else 136.0
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.14)
	_toast_tween.tween_interval(1.7)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.finished.connect(func() -> void: _toast_panel.visible = false)
