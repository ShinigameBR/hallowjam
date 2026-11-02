extends Node
## Temporary visual-capture harness. Run windowed, writes PNGs to tests/shots.

const OUT := "res://tests/shots/"


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _frames(3)
	await _capture_menu()
	await _capture_game()
	get_tree().quit(0)


func _capture_menu() -> void:
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await _wait(1.6)
	await _shot("01_menu")
	menu.call("_on_options")
	await _wait(0.4)
	await _shot("02_menu_options")
	menu.call("_hide_overlay", menu.get("_options"))
	await _wait(0.4)
	menu.call("_on_help")
	await _wait(0.4)
	await _shot("03_menu_help")
	menu.get("_help").call("close")
	await _wait(0.3)
	menu.queue_free()
	await _frames(2)


func _capture_game() -> void:
	GameState.start_new_game()
	for id in ["bucket", "screwdriver", "potion", "lavender_revived", "ruby", "rod", "oyster", "bait", "suitcase", "fish", "sapphire", "pearl"]:
		GameState.add_item(id)
	GameState.set_flag("book_read", true)
	GameState.set_flag("door_clue_seen", true)
	GameState.set_flag("front_door_open", true)
	GameState.set_flag("lavender_revived", true)
	GameState.set_flag("safe_open", true)
	GameState.set_flag("ruby_taken", true)
	GameState.set_flag("summoned_carmesim", true)
	GameState.set_flag("fish_caught", true)
	GameState.set_flag("intro_done", true)

	var game: Control = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await _frames(3)
	await _shot("04_room_main")
	await _shot_panel(game, "_book", "05_book")
	await _shot_panel(game, "_diary", "06_diary")
	await _shot_panel(game, "_circle", "07_circle")
	await _shot_panel(game, "_keypad", "08_keypad")
	await _shot_panel(game, "_pause", "09_pause")

	game.call("_apply_room", "main_left")
	await _frames(2)
	await _shot("10_room_left")
	game.call("_apply_room", "main_right")
	await _frames(2)
	await _shot("11_room_right")
	game.call("_apply_room", "outside")
	await _frames(2)
	await _shot("12_room_dock")

	var result: Control = load("res://scripts/game/monster_result_panel.gd").new()
	add_child(result)
	result.call("show_result", "carmesim")
	await _wait(0.4)
	await _shot("13_monster_result")
	result.queue_free()
	await _frames(2)

	game.get("_win").call("show_win")
	await _wait(0.4)
	await _shot("14_win")
	game.get("_win").call("close")
	await _wait(0.2)


func _shot_panel(game: Control, name: String, file: String) -> void:
	var overlay: Control = game.get(name)
	game.call("_open_overlay", overlay)
	await _wait(0.35)
	await _shot(file)
	overlay.call("close")
	await _wait(0.3)


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + file + ".png"))
	print("SHOT " + file)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
