extends Node
## Headless integration test for the Etapa 2 vertical slice.
##
## It drives the same entry points as real clicks (through RoomManager and the
## game controller) and checks the full Carmesim route:
##   bookshelf/page -> shelf corner/key -> lavender -> safe/ruby -> summon -> dock -> fish -> attic.

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
	await _wait(0.4)

	# ---------------------------------------------------- wrong summon (roxo)
	GameState.add_item("mushroom")
	GameState.add_item("water")
	await _open_circle()
	await _place("mushroom", 0)
	await _place("water", 1)
	_check(GameState.circle == ["mushroom", "water", "", ""], "two offerings placed in the circle")
	_game.call("_on_summon_requested")
	await _wait(0.7)
	var result: Control = _game.get("_monster_result")
	_check(result.visible, "monster result opens after a summon")
	_check(GameState.monsters_seen.has("roxo"), "mushroom + water summons the poison toad")
	result.call("dismiss")
	await _wait(0.4)
	await _finish_dialog()
	_check(GameState.circle == ["", "", "", ""], "failed summon empties the circle")
	_check(GameState.has_item("mushroom") and GameState.has_item("water"), "failed summon returns the offerings")

	# ------------------------------------------------------ page and shelf
	GameState.clear_selection()
	await _interact("bookshelf")
	var book_viewer: Control = _game.get("_book")
	_check(book_viewer.visible, "bookshelf opens the book page")
	_check(GameState.has_item("book_page"), "taking the page adds it to the inventory")
	_check(GameState.has_flag("picked_book_page"), "picking up the page sets its flag")
	_check(_game.get("_book_button").visible, "the page icon appears in the top corner")
	_check(GameState.has_flag("book_read"), "opening the page sets book_read")
	_check(book_viewer.find_children("*", "Label", true, false).is_empty(), "the page viewer has no text labels")
	await _close_overlay("_book")
	_check(GameState.objective.contains("lavanda"), "objective points at the lavender after the page")

	_game.get("_book_button").pressed.emit()
	await _wait(0.2)
	_check(book_viewer.visible, "the page icon opens the page viewer")
	await _close_overlay("_book")

	GameState.clear_selection()
	await _interact("bookshelf_corner")
	var shelf_zoom: Control = _game.get("_shelf")
	_check(shelf_zoom.visible, "shelf corner opens the shelf corner zoom")
	_check(not shelf_zoom.get_node("Background/Key").visible, "key hidden while the board is closed")
	_check(shelf_zoom.get_node("Background/Key").texture_click_mask != null, "the key only clicks on its drawing")
	shelf_zoom.call("_toggle_board")
	_check(shelf_zoom.get_node("Background/Key").visible, "opening the board shows the key")
	shelf_zoom.call("_take_key")
	await _finish_dialog()
	_check(GameState.has_item("key"), "key picked up from the shelf corner")
	_check(GameState.has_flag("picked_key"), "the shelf key sets its pickup flag")
	shelf_zoom.call("close")
	await _wait(0.7)
	_check(not shelf_zoom.visible, "shelf zoom closes")
	_check(not shelf_zoom.get("_board_open"), "leaving the zoom closes the board")

	# ------------------------------------------------------ front door clue
	GameState.clear_selection()
	await _interact("main_door")
	await _finish_dialog()
	_check(GameState.has_flag("door_clue_seen"), "locked front door writes its clue flag")
	_check(GameState.current_room == "main", "locked front door does not change rooms")

	# ------------------------------------------------------------ left side
	await _interact("left_door", 0.7)
	_check(GameState.current_room == "main_left", "left door reaches the left room")
	await _interact("bucket")
	await _finish_dialog()
	_check(GameState.has_item("bucket"), "bucket picked up")
	await _interact("left_drawers")
	await _wait(0.35)
	var drawers_zoom: Control = _game.get("_drawers")
	_check(drawers_zoom.visible, "drawers open the drawers zoom")
	_check(not drawers_zoom.get_node("Background/Screwdriver").visible, "screwdriver hidden while the drawer is closed")
	_check(drawers_zoom.get_node("Background/Screwdriver").texture_click_mask != null, "screwdriver only clicks on its drawing")
	drawers_zoom.call("_toggle_drawer")
	_check(drawers_zoom.get_node("Background/Screwdriver").visible, "opening the drawer shows the screwdriver")
	drawers_zoom.call("_take_screwdriver")
	await _finish_dialog()
	_check(GameState.has_item("screwdriver"), "screwdriver picked up")
	drawers_zoom.call("close")
	await _wait(0.7)
	_check(not drawers_zoom.visible, "drawers zoom closes")
	_check(not drawers_zoom.get("_drawer_open"), "leaving the zoom closes the drawer")

	# ----------------------------------------------------------- right side
	await _interact("left_back", 0.7)
	_check(GameState.current_room == "main", "left room returns to the main room")

	# The potion stays in the main room, next to the bookshelf.
	await _interact("potion")
	await _finish_dialog()
	_check(GameState.has_item("potion"), "potion picked up")

	await _interact("right_door", 0.7)
	_check(GameState.current_room == "main_right", "right door reaches the right room")

	GameState.clear_selection()
	_game.call("_on_item_clicked", "potion")
	_check(GameState.selected_item == "potion", "potion is selected before reviving the lavender")
	await _interact("lavender_wilted")
	await _finish_dialog()
	_check(GameState.has_flag("lavender_revived"), "potion revives the lavender")
	_check(not GameState.has_item("potion"), "reviving the lavender consumes the potion")

	await _interact("lavender_revived")
	await _finish_dialog()
	_check(GameState.has_item("lavender_revived"), "revived lavender picked up")

	# ---------------------------------------------------------------- safe
	await _interact("right_back", 0.7)
	_check(GameState.current_room == "main", "right room returns to the main room")
	GameState.clear_selection()
	await _interact("safe")
	await _wait(0.35)
	var safe_zoom: Control = _game.get("_safe")
	_check(safe_zoom.visible, "safe opens the chest zoom")
	for color_name in ["Red", "Red", "Blue", "Yellow", "Yellow", "Green"]:
		safe_zoom.call("_on_number_pressed", color_name)
	await _wait(0.6)
	safe_zoom.call("_take_ruby")
	await _wait(0.6)
	await _finish_dialog()
	_check(GameState.has_flag("safe_open"), "red 2, blue 1, yellow 2, green 1 opens the safe")
	_check(GameState.has_item("ruby"), "safe contains the ruby")
	_check(GameState.has_flag("ruby_taken"), "taking the ruby sets ruby_taken")

	# ------------------------------------------------------ summon Carmesim
	await _open_circle()
	await _place("lavender_revived", 0)
	await _place("ruby", 1)
	_check(GameState.circle == ["lavender_revived", "ruby", "", ""], "floral + red offerings placed")
	_game.call("_on_summon_requested")
	await _wait(0.8)
	result = _game.get("_monster_result")
	_check(result.visible, "successful summon shows the result card")
	_check(GameState.has_flag("summoned_carmesim"), "floral + red summons the Carmesim")
	_check(GameState.monsters_seen.has("carmesim"), "the Carmesim is recorded as seen")
	result.call("dismiss")
	await _wait(0.4)
	await _finish_dialog()
	_check(RoomManager.find_interactable("carmesim") != null, "the Carmesim appears in the main room")

	# ------------------------------------------------------ unlock the dock
	GameState.clear_selection()
	_game.call("_on_item_clicked", "key")
	_check(GameState.selected_item == "key", "key selected for the front door")
	await _interact("main_door", 0.7)
	await _finish_dialog()
	_check(GameState.current_room == "outside", "key opens the front door to the dock")
	_check(GameState.has_flag("front_door_open"), "front door stays open")
	_check(not GameState.has_item("key"), "the key is consumed")

	# ---------------------------------------------------------------- dock
	await _interact("rod")
	await _finish_dialog()
	await _interact("oyster")
	await _finish_dialog()
	_check(GameState.has_item("rod"), "fishing rod picked up")
	_check(GameState.has_item("oyster"), "oyster picked up")

	GameState.clear_selection()
	_game.call("_on_item_clicked", "bucket")
	_check(GameState.selected_item == "bucket", "bucket selected before filling it")
	await _interact("sea")
	await _finish_dialog()
	_check(GameState.has_item("bucket_water"), "bucket filled with seawater")
	_check(not GameState.has_item("bucket"), "filling replaces the empty bucket")

	await _interact("dirt")
	await _finish_dialog()
	_check(GameState.has_item("bait"), "digging finds the bait")
	_check(GameState.has_item("suitcase"), "digging finds the locked suitcase")
	_check(GameState.has_flag("dirt_dug"), "digging sets dirt_dug")

	_game.call("_on_item_clicked", "suitcase")
	await _finish_dialog()
	_check(GameState.selected_item == "", "inspecting the suitcase does not select it")

	GameState.clear_selection()
	_game.call("_on_item_clicked", "screwdriver")
	_check(GameState.selected_item == "screwdriver", "screwdriver selected")
	_game.call("_on_item_clicked", "oyster")
	await _finish_dialog()
	_check(GameState.has_item("pearl"), "screwdriver + oyster yields the pearl")
	_check(not GameState.has_item("oyster"), "opening the oyster consumes it")

	GameState.clear_selection()
	_game.call("_on_item_clicked", "bait")
	_check(GameState.selected_item == "bait", "bait selected for fishing")
	await _interact("sea")
	await _finish_dialog()
	_check(GameState.has_item("fish"), "bait + rod catches a fish")
	_check(not GameState.has_item("bait"), "fishing consumes the bait")
	_check(GameState.has_flag("fish_caught"), "fishing sets fish_caught")

	# ------------------------------------------------- optional sapphire
	await _interact("outside_door", 0.7)
	_check(GameState.current_room == "main", "dock returns to the main room")
	await _interact("right_door", 0.7)
	GameState.clear_selection()
	_game.call("_on_item_clicked", "bucket_water")
	await _interact("fireplace")
	await _finish_dialog()
	_check(GameState.has_flag("fire_out"), "water puts out the fireplace")
	_check(GameState.has_item("sapphire"), "the sapphire can be recovered from the ashes")
	await _interact("right_back", 0.7)
	_check(GameState.current_room == "main", "back from the right room before feeding")

	# ------------------------------------------------------- feed Carmesim
	GameState.clear_selection()
	_game.call("_on_item_clicked", "fish")
	_check(GameState.selected_item == "fish", "fish selected for the Carmesim")
	await _interact("carmesim")
	await _finish_dialog()
	_check(GameState.has_flag("carmesim_fed"), "feeding the Carmesim sets carmesim_fed")
	_check(not GameState.has_item("fish"), "feeding consumes the fish")

	# --------------------------------------------------------------- ending
	# The attic stair is on the left side of the main room.
	await _interact("left_door", 0.7)
	_check(GameState.current_room == "main_left", "the attic stair is reached from the left room")
	await _interact("attic_door")
	await _finish_dialog()
	await _wait(0.4)
	_check(GameState.has_flag("won"), "the attic door completes the slice")
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


func _interact(interaction_id: String, wait: float = 0.2) -> void:
	_game.call("_on_hotspot", interaction_id)
	await _wait(wait)


func _open_circle() -> void:
	await _open_overlay("_circle")


func _open_overlay(name: String) -> void:
	_game.call("_open_overlay", _game.get(name))
	await _wait(0.3)


func _close_overlay(name: String) -> void:
	_game.get(name).call("close")
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

	var book_viewer: Control = _game.get("_book")
	book_viewer.call("open")
	await _wait(0.3)
	_check(book_viewer.visible, "book page viewer opens")
	_check(book_viewer.find_children("*", "Label", true, false).is_empty(), "book page viewer shows only the page image")
	book_viewer.call("close")
	await _wait(0.3)

	var shelf_zoom: Control = _game.get("_shelf")
	shelf_zoom.call("open")
	await _wait(0.3)
	_check(shelf_zoom.visible, "shelf zoom opens")
	shelf_zoom.call("close")
	await _wait(0.7)

	var win_panel: Control = _game.get("_win")
	win_panel.call("show_win")
	await _wait(0.3)
	_audit_panel(win_panel, "win")
	win_panel.call("close")
	await _wait(0.3)

	var result_panel: Control = load("res://scripts/game/monster_result_panel.gd").new()
	add_child(result_panel)
	result_panel.call("show_result", "carmesim")
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
