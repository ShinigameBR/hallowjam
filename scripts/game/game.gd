extends Control
## Vertical-slice controller: rooms, hotspots, inventory use, the ritual and
## every panel in between. All persistent state lives in GameState.

const INVENTORY_BAR := preload("res://scripts/game/inventory_bar.gd")
const DIALOG_BOX := preload("res://scripts/game/dialog_box.gd")
const BOOK_PANEL := preload("res://scripts/game/book_panel.gd")
const CIRCLE_PANEL := preload("res://scripts/game/circle_panel.gd")
const SAFE_ZOOM := preload("res://scenes/components/safe_zoom.tscn")
const DRAWERS_ZOOM := preload("res://scenes/components/drawers_zoom.tscn")
const DIARY_PANEL := preload("res://scripts/game/diary_panel.gd")
const MONSTER_RESULT_PANEL := preload("res://scripts/game/monster_result_panel.gd")
const PAUSE_MENU := preload("res://scripts/game/pause_menu.gd")
const WIN_PANEL := preload("res://scripts/game/win_panel.gd")

const ROOM_NAMES := {
	"main": "SALA PRINCIPAL",
	"main_left": "LADO ESQUERDO",
	"main_right": "LADO DIREITO",
	"outside": "CAIS",
}

var _room_host: Control
var _inventory_bar: HBoxContainer
var _room_label: Label
var _objective_label: Label
var _selection_label: Label
var _dialog: Control
var _book: Control
var _circle: Control
var _safe: Control
var _drawers: Control
var _diary: Control
var _monster_result: Control
var _pause: Control
var _win: Control
var _fade: ColorRect
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

var _current_overlay: Control
var _changing_room := false
var _resolving_summon := false
var _save_clock := 0.0


func _ready() -> void:
	theme = UI.theme
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

	_safe = SAFE_ZOOM.instantiate()
	add_child(_safe)
	_safe.solved.connect(_on_safe_solved)
	_safe.closed.connect(func() -> void: _clear_overlay(_safe))

	_drawers = DRAWERS_ZOOM.instantiate()
	add_child(_drawers)
	_drawers.closed.connect(func() -> void: _clear_overlay(_drawers))

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
	GameState.flags_changed.connect(_on_flags_changed)
	GameState.dialogue_requested.connect(_on_dialogue_requested)
	GameState.panel_requested.connect(_on_panel_requested)
	GameState.action_requested.connect(_on_action)
	RoomManager.room_changed.connect(_on_room_changed)
	RoomManager.transition_started.connect(_on_transition_started)
	RoomManager.transition_finished.connect(_on_transition_finished)


# ================================================================== ROOMS
func _apply_room(room_id: String) -> void:
	var scene := RoomManager.get_room_scene(room_id)
	if scene == null:
		push_warning("No room scene registered for id '%s'." % room_id)
		scene = RoomManager.get_room_scene("main")
	if scene == null:
		return

	RoomManager.load_immediate(scene)
	if _room_label:
		_room_label.text = String(ROOM_NAMES.get(room_id, room_id.to_upper()))
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
	if id == "suitcase":
		_say("A maleta está trancada. Dois encaixes esperam por ponteiros: um marcado com o sol, outro com a lua.")
		return
	if GameState.selected_item == "screwdriver" and id == "oyster":
		_combine_oyster()
		return
	GameState.select_item(id)


func _combine_oyster() -> void:
	if not GameState.has_item("screwdriver") or not GameState.has_item("oyster"):
		return
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

	if result == ItemDB.TARGET:
		GameState.consume_circle()
		GameState.set_flag("summoned_carmesim", true)
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
		_say("O Beija-Flor Carmesim paira sobre o círculo. Ele espera ser alimentado.")
	else:
		GameState.clear_circle()
		_say("A fumaça se desfaz. As oferendas voltam para as suas mãos.")


func _on_safe_solved() -> void:
	_refresh_objective()
	await get_tree().create_timer(0.22).timeout
	_say("Você tira o rubi do baú e fecha a tampa do cofre. A pedra pulsa, quente, na palma da mão.")


# ================================================================== ENDING
func _finish_game() -> void:
	if _dialog.visible:
		return
	_show_dialog([
		{"speaker": "O BEIJA-FLOR CARMESIM", "text": "Ele devora o peixe e sobe até a porta do sótão. Um estalo seco, e a passagem cede."},
		{"text": "Você sobe. O escuro lá em cima cheira a poeira, madeira velha e metal molhado."},
		{"text": "Alguma coisa espera no sótão. A história continua."},
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
		{"text": "No livro sobre a mesa, está escrito: para abrir a passagem ao sótão, invoque o Beija-Flor Carmesim com aroma floral e algo vermelho."},
	])


func _say(text: String, speaker: String = "") -> void:
	_show_dialog([{"speaker": speaker, "text": text}])


func _show_dialog(lines: Array) -> void:
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


func _on_transition_finished() -> void:
	_changing_room = false


func _on_flags_changed() -> void:
	_refresh_objective()


func _on_dialogue_requested(lines: Array) -> void:
	_show_dialog(lines)


func _on_panel_requested(panel_id: String) -> void:
	match panel_id:
		"book":
			_open_overlay(_book)
		"circle":
			_open_overlay(_circle)
		"safe":
			_open_overlay(_safe)
		"drawers":
			_open_overlay(_drawers)
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
		"dig":
			_action_dig()
		"attic":
			_action_attic()
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


func _action_dig() -> void:
	if GameState.has_flag("dirt_dug"):
		return
	GameState.add_item("bait")
	GameState.add_item("suitcase")
	GameState.set_flag("dirt_dug", true)
	GameState.save_game()
	_say("Sob a terra molhada, uma minhoca gorda e uma maleta de couro. A maleta está trancada.")
	_refresh_objective()


func _action_attic() -> void:
	if GameState.has_flag("carmesim_fed"):
		_finish_game()


func _action_sea() -> void:
	if GameState.has_flag("fish_caught"):
		_say("O mar já te deu o que tinha.")
	elif not GameState.has_item("rod"):
		_say("O mar está violento. Sem uma vara, não dá para pescar.")
	elif not GameState.has_item("bait"):
		_say("Você tem a vara, mas falta isca. Talvez haja algo na terra do cais.")
	elif GameState.selected_item == "":
		_say("Selecione a isca no inventário para pescar.")
	else:
		_say("O mar espera.")


func _on_objective_changed(text: String) -> void:
	if _objective_label:
		_objective_label.text = text


func _refresh_objective() -> void:
	var text := "Leia o livro do bruxo."
	if GameState.has_flag("won"):
		text = "Você está livre."
	elif GameState.has_flag("carmesim_fed"):
		text = "A porta do sótão está aberta. Suba."
	elif GameState.has_flag("summoned_carmesim"):
		if GameState.has_flag("fish_caught"):
			text = "Alimente o Beija-Flor Carmesim com o peixe."
		elif not GameState.has_flag("front_door_open"):
			if not GameState.has_flag("picked_key"):
				text = "A porta da frente está trancada. A pista na porta aponta para uma tábua solta na estante."
			else:
				text = "Use a chave na porta da frente."
		elif not GameState.has_flag("picked_rod"):
			text = "No cais, pegue a vara de pescar."
		elif not GameState.has_flag("dirt_dug"):
			text = "Cave a terra suspeita no cais para encontrar isca."
		elif not GameState.has_flag("fish_caught"):
			text = "Selecione a isca e pesque no mar."
		else:
			text = "Alimente o Beija-Flor Carmesim com o peixe."
	elif not GameState.has_flag("book_read"):
		text = "Leia o livro do bruxo."
	elif not GameState.has_flag("lavender_revived"):
		text = "Revitalize a lavanda murcha do lado direito com a poção."
	elif not GameState.has_flag("picked_lavender_revived"):
		text = "Colha a lavanda revivida."
	elif not GameState.has_flag("ruby_taken"):
		text = "Abra o cofre da estante."
	else:
		text = "Invoque o Carmesim: coloque a lavanda revivida e o rubi no círculo."
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
		_selection_label.text = "Isca selecionada. Use no mar, com a vara."
	elif selected == "fish":
		_selection_label.text = "Peixe selecionado. Ofereça ao Carmesim."
	elif selected == "ruby" or selected == "lavender_revived":
		_selection_label.text = "Usando: %s. Coloque no círculo." % ItemDB.item_name(selected)
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
