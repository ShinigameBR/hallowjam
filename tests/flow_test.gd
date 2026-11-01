extends Node
## Temporary integration test. Runs headless and drives the whole slice.

var _failures: Array[String] = []
var _game: Control


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	await _run()
	print("\n=== FLOW TEST ===")
	if _failures.is_empty():
		print("PASS: every check succeeded.")
	else:
		for failure in _failures:
			print("FAIL: " + failure)
	print("=================\n")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _run() -> void:
	_game = load("res://scenes/game.tscn").instantiate()
	add_child(_game)
	await get_tree().process_frame
	await get_tree().process_frame
	await _finish_dialog()

	print("VIEWPORT %s GAME %s" % [get_viewport().get_visible_rect().size, _game.size])
	await _audit_overlays()
	GameState.start_new_game()
	_game.call("_rebuild_hotspots")
	await get_tree().process_frame

	# ---------------------------------------------------------- wrong summon
	GameState.add_item("mushroom")
	GameState.add_item("water")
	await _open_circle()
	await _place("mushroom", 0)
	await _place("water", 1)
	_game.call("_on_summon_requested")
	await _wait(0.7)
	var result: Control = _game.get("_monster_result")
	_check(result.visible, "monster result opens after a summon")
	_check(GameState.monsters_seen.has("roxo"), "mushroom + water summons the purple toad")
	result.call("dismiss")
	await _wait(0.4)
	await _finish_dialog()
	_check(GameState.circle == ["", "", "", ""], "failed summon empties the circle")
	_check(GameState.has_item("mushroom") and GameState.has_item("water"), "failed summon returns the offerings")

	# ---------------------------------------------------------- explore
	_game.call("_on_hotspot", "mushrooms")
	await _finish_dialog()
	_game.call("_on_hotspot", "feather")
	await _finish_dialog()
	_game.call("_on_hotspot", "music_box")
	await _finish_dialog()
	_check(GameState.has_item("mushroom"), "mushroom picked up")
	_check(GameState.has_item("feather"), "feather picked up from the windowsill")
	_check(GameState.has_item("music_box"), "music box picked up")

	_game.call("_on_hotspot", "kitchen_door")
	await _wait(0.7)
	_check(GameState.current_room == "kitchen", "kitchen door works")

	for id in ["knife", "candle", "syringe", "potion"]:
		_game.call("_on_hotspot", id)
		await _finish_dialog()
	_game.call("_on_hotspot", "shelves")
	await _finish_dialog()
	_game.call("_on_hotspot", "sink")
	await _finish_dialog()
	_check(GameState.has_item("knife"), "knife picked up")
	_check(GameState.has_item("candle"), "candle picked up")
	_check(GameState.has_item("syringe"), "syringe picked up")
	_check(GameState.has_item("potion"), "potion picked up")
	_check(GameState.has_item("sardines"), "sardines picked up")
	_check(GameState.has_item("water"), "water picked up")

	_game.call("_on_item_clicked", "syringe")
	_game.call("_on_item_clicked", "potion")
	await _finish_dialog()
	_check(GameState.has_item("tranq"), "syringe + potion makes the tranquilizer")
	_check(not GameState.has_item("syringe") and not GameState.has_item("potion"), "combine consumes the parts")

	_game.call("_on_hotspot", "kitchen_door")
	await _wait(0.7)
	_game.call("_on_hotspot", "basement_door")
	await _wait(0.7)
	_check(GameState.current_room == "basement", "basement door works")

	_game.call("_on_hotspot", "dark")
	await _finish_dialog()
	_check(GameState.has_flag("basement_lit"), "candle lights the basement")
	_game.call("_on_hotspot", "rod")
	await _finish_dialog()
	_check(GameState.has_item("rod"), "fishing rod picked up")

	_game.call("_on_item_clicked", "tranq")
	_game.call("_on_hotspot", "creature")
	await _finish_dialog()
	_check(GameState.has_flag("creature_tranquilized"), "tranquilizer calms the creature")
	_game.call("_on_item_clicked", "knife")
	_game.call("_on_hotspot", "creature")
	await _finish_dialog()
	_check(GameState.has_item("meat"), "knife on the sleeping creature yields meat")

	# ---------------------------------------------------------- safe
	_game.call("_on_hotspot", "basement_door")
	await _wait(0.7)
	await _open_overlay("_keypad")
	for digit in ["3", "1", "4", "2"]:
		_game.get("_keypad").call("_press_digit", digit)
	_game.get("_keypad").call("_submit")
	await _wait(0.5)
	await _finish_dialog()
	_check(GameState.has_flag("safe_open"), "code 3142 opens the safe")
	_check(GameState.has_item("diary"), "safe contains the diary")

	# ---------------------------------------------------------- ritual
	await _open_circle()
	await _place("meat", 0)
	await _place("feather", 1)
	await _place("water", 2)
	await _place("sardines", 3)
	_check(GameState.circle == ["meat", "feather", "water", "sardines"], "four offerings placed")
	_game.call("_on_summon_requested")
	await _wait(0.8)
	result = _game.get("_monster_result")
	_check(result.visible, "successful summon shows the result")
	_check(GameState.has_flag("summoned_green"), "food + wind + water summons the green wanderer")
	result.call("dismiss")
	await _wait(0.4)
	await _finish_dialog()

	# ---------------------------------------------------------- ending
	_game.call("_on_hotspot", "main_door")
	await _wait(0.7)
	_check(GameState.current_room == "outside", "front door reaches the dock")
	_game.call("_on_hotspot", "companion")
	await _finish_dialog()
	await _wait(0.4)
	_check(GameState.has_flag("won"), "talking to the companion completes the slice")
	_check(_game.get("_win").visible, "win panel is visible")
	_check(not GameState.has_save(), "winning deletes the run save")

	await _audit_menu()


func _audit_menu() -> void:
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await _wait(1.4)
	var content: Control = menu.get("_content")
	var content_rect := Rect2(content.global_position, content.size)
	print("LAYOUT %-15s pos=%s size=%s" % ["menu content", content_rect.position, content_rect.size])
	var children_bottom := content_rect.position.y
	for child in content.get_children():
		if child is Control and child.visible:
			children_bottom = maxf(children_bottom, child.global_position.y + child.size.y)
	print("LAYOUT %-15s children_bottom=%.1f footer_top=%.1f" % ["menu content", children_bottom, 720.0 * 0.935])
	_check(children_bottom <= 720.0 * 0.935, "menu content clears the footer")
	_check(content_rect.position.y >= -1.0 and content_rect.end.y <= 721.0, "menu content fits vertically")
	_check(content_rect.position.x >= -1.0 and content_rect.end.x <= 1281.0, "menu content fits horizontally")
	for button in menu.get("_buttons"):
		var rect := Rect2(button.global_position, button.size)
		_check(rect.end.x <= 1281.0 and rect.end.y <= 721.0, "menu button '%s' fits on screen" % button.text)
		_check(rect.size.x > 100.0 and rect.size.y > 30.0, "menu button '%s' has a usable size" % button.text)

	menu.call("_on_options")
	await _wait(0.3)
	_audit_panel(menu.get("_options"), "menu options", menu.get("_options_panel"))
	menu.call("_hide_overlay", menu.get("_options"))
	await _wait(0.3)

	menu.call("_on_help")
	await _wait(0.3)
	_audit_panel(menu.get("_help"), "menu help")
	menu.get("_help").call("close")
	await _wait(0.3)
	menu.queue_free()


# ------------------------------------------------------------------ helpers
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _finish_dialog() -> void:
	var dialog: Control = _game.get("_dialog")
	var guard := 0
	while dialog.visible and guard < 80:
		dialog.call("advance")
		await get_tree().process_frame
		guard += 1
	if dialog.visible:
		_check(false, "dialog failed to close")


func _open_circle() -> void:
	await _open_overlay("_circle")


func _open_overlay(name: String) -> void:
	_game.call("_open_overlay", _game.get(name))
	await _wait(0.3)


func _place(item_id: String, slot: int) -> void:
	_game.call("_on_item_clicked", item_id)
	_game.get("_circle").call("_on_slot_pressed", slot)
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _audit_overlays() -> void:
	for entry in [
		["_book", "book"],
		["_keypad", "keypad"],
		["_diary", "diary"],
		["_circle", "circle"],
		["_pause", "pause"],
	]:
		var overlay: Control = _game.get(entry[0])
		overlay.call("open")
		await _wait(0.3)
		_audit_panel(overlay, String(entry[1]))
		overlay.call("close")
		await _wait(0.3)

	var win_panel: Control = _game.get("_win")
	win_panel.call("show_win")
	await _wait(0.3)
	_audit_panel(win_panel, "win")
	win_panel.call("close")
	await _wait(0.3)

	var result_panel: Control = load("res://scripts/game/monster_result_panel.gd").new()
	add_child(result_panel)
	result_panel.call("show_result", "verde")
	await _wait(0.3)
	_audit_panel(result_panel, "monster result")
	result_panel.call("close")
	await _wait(0.3)
	result_panel.queue_free()

	var help_panel: Control = load("res://scripts/ui/help_panel.gd").new()
	add_child(help_panel)
	help_panel.call("open")
	await _wait(0.3)
	_audit_panel(help_panel, "help")
	help_panel.call("close")
	await _wait(0.3)
	help_panel.queue_free()


func _audit_panel(overlay: Control, label: String, explicit_panel: Control = null) -> void:
	var panel: Control = explicit_panel
	if panel == null:
		panel = overlay.get("panel") if overlay.get("panel") != null else overlay.get("_panel")
	if panel == null:
		_check(false, "%s panel missing" % label)
		return
	var pos := panel.global_position
	var panel_size := panel.size
	var center: Control = overlay.get("_center")
	print("LAYOUT %-15s pos=%s size=%s overlay=%s center=%s" % [label, pos, panel_size, overlay.size, center.size if center else Vector2.ZERO])
	_check(panel_size.x > 200.0 and panel_size.y > 120.0, "%s panel has a usable size" % label)
	_check(pos.x >= -1.0 and pos.y >= -1.0, "%s panel starts on screen" % label)
	_check(pos.x + panel_size.x <= 1281.0, "%s panel fits horizontally" % label)
	_check(pos.y + panel_size.y <= 721.0, "%s panel fits vertically" % label)
