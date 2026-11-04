extends Node
## Headless integration test for the Etapa 2 vertical slice.
##
## It drives the same entry points as real clicks (through RoomManager and the
## game controller) and checks the full Carmesim route:
##   book page -> shelf corner/key -> lavender -> safe/ruby -> summon -> dock -> fish
##   -> attic door -> attic dark -> branco light -> chest 31542 -> blue scale.

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

	# ---------------------------------------------------- inventory toggle
	var inventory_toggle: Button = _game.get("_inventory_toggle")
	var inventory_panel: Control = _game.get("_inventory_panel")
	_check(not inventory_panel.visible, "inventory bar starts closed")
	inventory_toggle.pressed.emit()
	await _wait(0.3)
	_check(inventory_panel.visible, "the inventory button opens the bottom bar")
	_check(inventory_toggle.text == "FECHAR", "the inventory button becomes a close action")
	inventory_toggle.pressed.emit()
	await _wait(0.3)
	_check(not inventory_panel.visible, "the inventory button closes the bottom bar")

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
	await _interact("book_page")
	await _finish_dialog()
	var book_viewer: Control = _game.get("_book")
	_check(not book_viewer.visible, "picking up the page does not open it")
	_check(GameState.has_item("book_page"), "taking the page adds it to the inventory")
	_check(GameState.has_flag("picked_book_page"), "picking up the page sets its flag")
	_check(_game.get("_book_button").visible, "the page icon appears in the top corner")
	_check(not GameState.has_flag("book_read"), "picking up the page does not read it yet")

	_game.get("_book_button").pressed.emit()
	await _wait(0.2)
	_check(book_viewer.visible, "the page icon opens the page viewer")
	_check(GameState.has_flag("book_read"), "opening the page sets book_read")
	_check(book_viewer.find_children("*", "Label", true, false).is_empty(), "the page viewer has no text labels")
	await _close_overlay("_book")
	_check(GameState.objective.contains("lavanda"), "objective points at the lavender after the page")

	GameState.clear_selection()
	_check(RoomManager.find_interactable("bookshelf_corner") == null, "shelf corner is hidden before the door hint")
	await _interact("bookshelf_corner")
	var shelf_zoom: Control = _game.get("_shelf")
	_check(not shelf_zoom.visible, "shelf corner stays closed before the door hint")

	# ------------------------------------------------------ front door hint
	await _interact("hint_door")
	_check(_game.get("_door_hint").visible, "first click on the front door opens the hint")
	_check(GameState.has_flag("door_clue_seen"), "the door hint writes its clue flag")
	_check(RoomManager.find_interactable("hint_door") == null, "the hint hotspot hides after the first look")
	await _close_overlay("_door_hint")

	await _interact("bookshelf_corner")
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
	var rod_zoom: Control = _game.get("_rod")
	_check(rod_zoom.visible, "the rod opens the rod zoom")
	_check(rod_zoom.get_node("Background/Oyster").visible, "the oyster hangs from the hook")
	_check(not rod_zoom.get_node("Background/Fish").visible, "no fish before casting")
	rod_zoom.call("_use_hook")
	await _finish_dialog()
	_check(not GameState.has_flag("rod_cast"), "the hook is blocked while the oyster is on it")
	rod_zoom.call("_take_oyster")
	await _finish_dialog()
	_check(GameState.has_item("oyster"), "oyster picked from the rod")
	_check(not rod_zoom.get_node("Background/Oyster").visible, "picked oyster leaves the hook")
	rod_zoom.call("_use_hook")
	await _finish_dialog()
	_check(not GameState.has_flag("rod_cast"), "the rod cannot be cast without bait")
	rod_zoom.call("close")
	await _wait(0.3)
	_check(not rod_zoom.visible, "rod zoom closes")

	GameState.clear_selection()
	_game.call("_on_item_clicked", "bucket")
	_check(GameState.selected_item == "bucket", "bucket selected before filling it")
	await _interact("sea")
	await _finish_dialog()
	_check(GameState.has_item("bucket_water"), "bucket filled with seawater")
	_check(not GameState.has_item("bucket"), "filling replaces the empty bucket")

	await _interact("dirt")
	var hole_zoom: Control = _game.get("_hole")
	_check(hole_zoom.visible, "dirt opens the hole zoom")
	_check(not hole_zoom.get_node("Background/Bait").visible, "bait hidden before digging")
	_check(not hole_zoom.get_node("Background/Suitcase").visible, "suitcase hidden before digging")
	hole_zoom.call("_dig")
	await _finish_dialog()
	_check(GameState.has_flag("dirt_dug"), "digging sets dirt_dug")
	_check(not GameState.has_item("bait"), "digging does not pick the bait by itself")
	_check(hole_zoom.get_node("Background/Bait").visible, "digging shows the bait")
	var dock_bg: TextureRect = RoomManager.current_room_node().get_node("Background")
	_check(dock_bg.texture.resource_path.ends_with("cais_buraco_cavado.png"), "digging swaps the dock background")
	hole_zoom.call("close")
	await _wait(0.3)
	_check(not hole_zoom.visible, "hole zoom closes")

	# Os itens ficam no buraco esperando, e o buraco continua cavado.
	await _interact("dirt")
	_check(hole_zoom.visible, "hole zoom reopens")
	_check(not hole_zoom.get_node("Background/Hole").visible, "the hole stays dug")
	hole_zoom.call("_take_bait")
	await _finish_dialog()
	hole_zoom.call("_take_suitcase")
	await _finish_dialog()
	_check(GameState.has_item("bait"), "bait picked from the hole")
	_check(GameState.has_item("suitcase"), "suitcase picked from the hole")
	_check(not hole_zoom.get_node("Background/Bait").visible, "picked bait leaves the hole")
	hole_zoom.call("close")
	await _wait(0.3)

	_game.call("_on_item_clicked", "suitcase")
	await _wait(0.3)
	var suitcase_zoom: Control = _game.get("_suitcase")
	_check(suitcase_zoom.visible, "clicking the suitcase opens its zoom")
	_check(GameState.selected_item == "", "opening the suitcase does not select it")
	# Ponteiro errado não abre: só o sol no 3.
	for i in 3:
		suitcase_zoom.get_node("Background/SunDial").pressed.emit()
	await _wait(0.3)
	_check(suitcase_zoom.visible and not GameState.has_item("music_box"), "only the sun hand right keeps the suitcase locked")
	suitcase_zoom.call("close")
	await _wait(0.3)
	_check(not suitcase_zoom.visible, "suitcase zoom closes")

	# Os ponteiros ficam onde estavam: falta só a lua no 11.
	_game.call("_on_item_clicked", "suitcase")
	await _wait(0.3)
	for i in 11:
		suitcase_zoom.get_node("Background/MoonDial").pressed.emit()
	await _wait(1.0)
	_check(not suitcase_zoom.visible, "solving the suitcase closes its zoom")
	_check(GameState.has_item("music_box"), "sun on 3 + moon on 11 gives the music box")
	_check(not GameState.has_item("suitcase"), "the opened suitcase leaves the inventory")
	_check(ItemDB.item_tags("music_box").has("feelings"), "the music box counts as something with feelings")
	_check(ItemDB.resolve_summon(["music_box", "shell"]) == "branco", "music box + ocean item summons A Luz que Escuta")
	_check(load(String(ItemDB.item("music_box").get("texture", ""))) is Texture2D, "the music box has its own art")
	await _finish_dialog()

	GameState.clear_selection()
	_game.call("_on_item_clicked", "screwdriver")
	_check(GameState.selected_item == "screwdriver", "screwdriver selected")
	_game.call("_on_item_clicked", "oyster")
	await _finish_dialog()
	_check(GameState.has_item("pearl"), "screwdriver + oyster yields the pearl")
	_check(not GameState.has_item("oyster"), "opening the oyster consumes it")

	GameState.clear_selection()
	await _interact("rod")
	_check(rod_zoom.visible, "rod zoom reopens")
	_check(not rod_zoom.get_node("Background/Oyster").visible, "the oyster stays picked")
	rod_zoom.call("_use_hook")
	await _finish_dialog()
	_check(not GameState.has_flag("rod_cast"), "the hook needs the bait selected")
	GameState.select_item("bait")
	rod_zoom.call("_use_hook")
	await _wait(1.2)
	await _finish_dialog()
	_check(GameState.has_flag("rod_cast"), "bait on the hook casts the line")
	_check(not GameState.has_item("bait"), "casting consumes the bait")
	_check(not GameState.has_item("fish"), "casting does not pick the fish by itself")
	_check(rod_zoom.get_node("Background").texture.resource_path.ends_with("zoom_vara_esticada.jpeg"), "casting stretches the rod")
	_check(rod_zoom.get_node("Background/Fish").visible, "a fish hangs from the line")
	rod_zoom.call("_take_fish")
	await _finish_dialog()
	_check(GameState.has_item("fish"), "fish picked from the line")
	_check(GameState.has_flag("fish_caught"), "picking the fish sets fish_caught")
	_check(not rod_zoom.get_node("Background/Fish").visible, "picked fish leaves the line")
	rod_zoom.call("close")
	await _wait(0.3)

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

	# ------------------------------------------------------ attic door
	# The Carmesim leaves the main room and forces the attic door on the left.
	_check(RoomManager.find_interactable("carmesim") == null, "the fed Carmesim leaves the main room")
	await _interact("left_door", 0.7)
	_check(GameState.current_room == "main_left", "the attic stair is reached from the left room")
	var guard := 0
	while not GameState.has_flag("attic_door_open") and guard < 300:
		await _finish_dialog()
		await get_tree().process_frame
		guard += 1
	await _finish_dialog()
	_check(GameState.has_flag("attic_door_open"), "the Carmesim opens the attic door")
	await _interact("attic_door", 0.7)
	await _wait(0.5)
	_check(GameState.current_room == "attic", "the open attic door leads to the attic")
	_check(not GameState.has_flag("won"), "reaching the attic does not end the game")
	_check(not _game.get("_win").visible, "win panel stays hidden")
	var attic_room := RoomManager.current_room_node()
	var attic_bg: TextureRect = attic_room.get_node("Background")
	_check(attic_bg.texture.resource_path.ends_with("sotao.jpeg"), "the attic starts dark")

	# No escuro, tudo responde com a mesma desculpa; só a porta de volta funciona.
	_check(RoomManager.find_interactable("attic_darkness") != null, "the dark attic is clickable")
	_check(RoomManager.find_interactable("attic_chest") == null, "the chest is hidden in the dark")
	await _interact("attic_darkness")
	await _finish_dialog()
	_check(GameState.current_room == "attic", "the dark attic keeps the player in the room")
	_check(RoomManager.find_interactable("attic_door") != null, "the attic door stays clickable in the dark")

	# Back to the circle: music box + pearl (feelings + ocean) summons the white light.
	await _interact("attic_door", 0.7)
	_check(GameState.current_room == "main_left", "the attic door returns to the left room")
	await _interact("left_back", 0.7)
	_check(GameState.current_room == "main", "the left room returns to the main room")
	await _open_circle()
	await _place("music_box", 0)
	await _place("pearl", 1)
	_check(GameState.circle == ["music_box", "pearl", "", ""], "music box + pearl placed in the circle")
	_game.call("_on_summon_requested")
	await _wait(0.8)
	result = _game.get("_monster_result")
	_check(result.visible, "the branco summon shows its result card")
	_check(GameState.has_flag("summoned_branco"), "music box + pearl summons A Luz que Escuta")
	_check(not GameState.has_item("music_box"), "the white light consumes the offerings")
	_check(result.get("_action").text == "SEGUIR A LUZ", "the branco result invites the player to follow the light")
	result.call("dismiss")
	await _wait(0.4)
	var branco_dialog: Control = _game.get("_dialog")
	branco_dialog.call("advance")
	await get_tree().process_frame
	_check(branco_dialog.get("_text").text.contains("esquerdo"), "the branco summon points the player to the left")
	_check(branco_dialog.get("_text").text.contains("sótão"), "the branco summon points the player to the attic")
	await _finish_dialog()

	# ---------------------------------------------------------- lit attic
	await _interact("left_door", 0.7)
	await _interact("attic_door")
	await _finish_dialog()
	await _wait(0.5)
	attic_bg = RoomManager.current_room_node().get_node("Background")
	_check(attic_bg.texture.resource_path.ends_with("sotao_iluminado_pela_invocacao_branco.png"), "the white summon lights the attic")

	await _interact("attic_chest")
	await _wait(0.4)
	var chest_zoom: Control = _game.get("_attic_chest")
	_check(chest_zoom.visible, "the attic chest opens its zoom")
	for i in 3:
		chest_zoom.get_node("Background/Dial1").pressed.emit()
	for i in 1:
		chest_zoom.get_node("Background/Dial2").pressed.emit()
	for i in 5:
		chest_zoom.get_node("Background/Dial3").pressed.emit()
	for i in 4:
		chest_zoom.get_node("Background/Dial4").pressed.emit()
	for i in 2:
		chest_zoom.get_node("Background/Dial5").pressed.emit()
	await _wait(0.8)
	await _finish_dialog()
	_check(GameState.has_flag("attic_chest_open"), "3 1 5 4 2 opens the attic chest")
	_check(not chest_zoom.visible, "solving the chest closes its zoom")
	attic_bg = RoomManager.current_room_node().get_node("Background")
	_check(attic_bg.texture.resource_path.ends_with("sotao_pela_invocacao_branco_bau_ja_aberto.png"), "the open chest swaps the attic background")
	_check(RoomManager.find_interactable("escama_azul") != null, "the blue scale waits inside the open chest")

	await _interact("escama_azul")
	await _finish_dialog()
	_check(GameState.has_item("escama_azul"), "the blue scale can be collected")
	_check(GameState.has_flag("picked_escama_azul"), "picking the scale sets its flag")
	_check(RoomManager.find_interactable("escama_azul") == null, "the picked scale leaves the chest")
	_check(GameState.objective.contains("escama"), "objective follows the blue scale")

	# O Carmesim continua no lado esquerdo depois de abrir a porta e sorri.
	await _interact("attic_door", 0.7)
	_check(GameState.current_room == "main_left", "the attic door returns to the left room")
	_check(RoomManager.find_interactable("carmesim_left") != null, "the Carmesim waits in the left room")
	await _interact("carmesim_left")
	var dialog: Control = _game.get("_dialog")
	dialog.call("advance")
	await get_tree().process_frame
	_check(dialog.get("_text").text.contains("sorri"), "clicking the Carmesim after the door shows its smile")
	await _finish_dialog()

	await _audit_menu()

	# ---------------------------------------------------------- azul ending
	# O azul precisa de oceano + cheiro forte + solidão. A concha não aparece
	# na rota ativa, então é injetada aqui só para exercitar o final.
	GameState.clear_selection()
	GameState.add_item("shell")
	GameState.add_item("mushroom")
	await _open_circle()
	await _place("shell", 0)
	await _place("mushroom", 1)
	_check(GameState.circle == ["shell", "mushroom", "", ""], "shell + mushroom placed for the azul summon")
	_game.call("_on_summon_requested")
	await _wait(0.8)
	result = _game.get("_monster_result")
	_check(result.visible, "the azul summon shows its result card")
	_check(result.get("_name").text == "O Cego das Profundezas", "shell + mushroom summons the azul")
	_check(result.get("_action").text == "ENFRENTAR", "the azul result offers the final confrontation")
	result.call("dismiss")
	await _wait(0.4)
	await _finish_dialog()
	await _wait(0.3)
	_check(GameState.has_flag("azul_ending"), "the azul summon marks the azul ending")
	_check(GameState.has_flag("won"), "the azul summon ends the game")
	_check(_game.get("_win").visible, "the azul summon opens the ending screen")
	_check(not GameState.has_save(), "the ending removes the save file")


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
