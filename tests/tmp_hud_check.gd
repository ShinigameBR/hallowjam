extends Node

var _game: Control


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	GameState.start_new_game()
	for id in ["bucket", "screwdriver", "potion", "rod", "bait", "fish", "ruby", "lavender_revived", "oyster", "suitcase", "pearl", "sapphire"]:
		GameState.add_item(id)
	_game = load("res://scenes/game.tscn").instantiate()
	add_child(_game)
	await get_tree().process_frame
	await get_tree().process_frame
	var dialog: Control = _game.get("_dialog")
	while dialog.visible:
		dialog.call("advance")
		await get_tree().process_frame
	GameState.start_new_game()
	for id in ["bucket", "screwdriver", "potion", "rod", "bait", "fish", "ruby", "lavender_revived", "oyster", "suitcase", "pearl", "sapphire"]:
		GameState.add_item(id)
	_game.call("_rebuild_hotspots")
	await get_tree().create_timer(0.4).timeout

	for path in ["HudRoomBlock", "HudRoomBlock/RoomCard", "HudActions", "InventoryPanel", "InventoryToggle"]:
		var node: Control = _game.get_node(path)
		print(path, " rect=", node.get_global_rect(), " visible=", node.visible)
	print("objective rect=", _game.get("_objective_label").get_global_rect())
	print("safe rect=", RoomManager.find_interactable("safe").get_global_rect())
	await _click(RoomManager.find_interactable("safe").get_global_rect().get_center())
	print("safe opened=", _game.get("_safe").visible)
	_game.get("_safe").call("close")
	await get_tree().create_timer(0.3).timeout

	await _click(_game.get("_inventory_toggle").get_global_rect().get_center())
	await get_tree().create_timer(0.4).timeout
	print("inventory open=", _game.get("_inventory_panel").visible)
	print("inventory panel rect=", _game.get("_inventory_panel").get_global_rect())
	print("inventory bar rect=", _game.get("_inventory_bar").get_global_rect())
	print("toggle rect=", _game.get("_inventory_toggle").get_global_rect())
	var first_slot: Button = _game.get("_inventory_bar").get_child(0)
	print("slot 0 rect=", first_slot.get_global_rect())
	await _click(first_slot.get_global_rect().get_center())
	print("selected=", GameState.selected_item)
	await _click(_game.get("_inventory_toggle").get_global_rect().get_center())
	await get_tree().create_timer(0.4).timeout
	print("inventory closed=", not _game.get("_inventory_panel").visible)
	get_tree().quit()


func _click(pos: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	get_viewport().push_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	get_viewport().push_input(up)
	await get_tree().process_frame
