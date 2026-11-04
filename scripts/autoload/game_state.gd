extends Node
## Single source of truth for the current run.
## Everything that needs to survive a scene change (or a closed game) lives here.

signal inventory_changed
signal circle_changed
signal selection_changed
signal flags_changed
signal objective_changed(text: String)
signal toast(text: String)
signal dialogue_requested(lines: Array)
signal panel_requested(panel_id: String)
signal action_requested(action_id: String, source: Node)

const SAVE_PATH := "user://circulo_run.cfg"
const ROOMS := ["main", "main_left", "main_right", "outside"]

var inventory: Array[String] = []
var circle: Array[String] = ["", "", "", ""]
var flags: Dictionary = {}
var current_room: String = "main"
var objective: String = "Uma página solta repousa sobre a estante."
var play_time: float = 0.0
var monsters_seen: Array[String] = []
var selected_item: String = ""
var run_started: bool = false


func start_new_game() -> void:
	inventory.clear()
	circle = ["", "", "", ""]
	flags.clear()
	current_room = "main"
	objective = "Uma página solta repousa sobre a estante."
	play_time = 0.0
	monsters_seen.clear()
	selected_item = ""
	run_started = true
	save_game()
	_emit_all()


func _emit_all() -> void:
	inventory_changed.emit()
	circle_changed.emit()
	selection_changed.emit()
	flags_changed.emit()
	objective_changed.emit(objective)


# ------------------------------------------------------------------ inventory
func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func item_count(item_id: String) -> int:
	var n := 0
	for id in inventory:
		if id == item_id:
			n += 1
	return n


func add_item(item_id: String) -> void:
	if not ItemDB.ITEMS.has(item_id):
		push_warning("Item desconhecido: %s" % item_id)
		return
	inventory.append(item_id)
	inventory_changed.emit()


func remove_item(item_id: String) -> bool:
	var index := inventory.find(item_id)
	if index < 0:
		return false
	inventory.remove_at(index)
	if selected_item == item_id and not inventory.has(item_id):
		selected_item = ""
		selection_changed.emit()
	inventory_changed.emit()
	return true


func replace_item(old_id: String, new_id: String) -> bool:
	if not remove_item(old_id):
		return false
	add_item(new_id)
	return true


func select_item(item_id: String) -> void:
	if item_id != "" and not inventory.has(item_id):
		return
	if selected_item == item_id:
		selected_item = ""
	else:
		selected_item = item_id
	selection_changed.emit()


func clear_selection() -> void:
	if selected_item == "":
		return
	selected_item = ""
	selection_changed.emit()


# ------------------------------------------------------------------ circle
func place_in_circle(slot: int, item_id: String) -> bool:
	if slot < 0 or slot >= 4:
		return false
	if circle[slot] != "":
		return false
	if not remove_item(item_id):
		return false
	circle[slot] = item_id
	selected_item = ""
	selection_changed.emit()
	circle_changed.emit()
	save_game()
	return true


func take_from_circle(slot: int) -> void:
	if slot < 0 or slot >= 4 or circle[slot] == "":
		return
	var item_id := circle[slot]
	circle[slot] = ""
	inventory.append(item_id)
	inventory_changed.emit()
	circle_changed.emit()
	save_game()


func clear_circle() -> void:
	var changed := false
	for i in range(4):
		if circle[i] != "":
			inventory.append(circle[i])
			circle[i] = ""
			changed = true
	if changed:
		inventory_changed.emit()
		circle_changed.emit()
		save_game()


func consume_circle() -> void:
	circle = ["", "", "", ""]
	circle_changed.emit()
	save_game()


# ------------------------------------------------------------------ flags
func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	flags_changed.emit()


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func clear_flag(key: String) -> void:
	if flags.erase(key):
		flags_changed.emit()


func set_objective(text: String) -> void:
	objective = text
	objective_changed.emit(objective)


func track_monster(monster_id: String) -> void:
	if monster_id == "none":
		return
	if not monsters_seen.has(monster_id):
		monsters_seen.append(monster_id)


func notify(text: String) -> void:
	toast.emit(text)


## Convenience helpers used by room components.
func say(text: String, speaker: String = "") -> void:
	if text.strip_edges() == "":
		return
	dialogue_requested.emit([{"speaker": speaker, "text": text}])


func show_dialog(lines: Array) -> void:
	if lines.is_empty():
		return
	dialogue_requested.emit(lines)


func open_panel(panel_id: String) -> void:
	panel_requested.emit(panel_id)


func request_action(action_id: String, source: Node = null) -> void:
	action_requested.emit(action_id, source)


# ------------------------------------------------------------------ persistence
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	if not run_started:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("run", "inventory", inventory)
	cfg.set_value("run", "circle", circle)
	cfg.set_value("run", "flags", flags)
	cfg.set_value("run", "current_room", current_room)
	cfg.set_value("run", "objective", objective)
	cfg.set_value("run", "play_time", play_time)
	cfg.set_value("run", "monsters_seen", monsters_seen)
	cfg.save(SAVE_PATH)


func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false

	inventory.clear()
	var saved_inventory: Variant = cfg.get_value("run", "inventory", [])
	if saved_inventory is Array:
		for raw in saved_inventory:
			var id := String(raw)
			if ItemDB.ITEMS.has(id):
				inventory.append(id)

	circle = ["", "", "", ""]
	var saved_circle: Variant = cfg.get_value("run", "circle", [])
	if saved_circle is Array:
		for i in range(mini(4, saved_circle.size())):
			var id := String(saved_circle[i])
			if id != "" and ItemDB.ITEMS.has(id):
				circle[i] = id

	flags.clear()
	var saved_flags: Variant = cfg.get_value("run", "flags", {})
	if saved_flags is Dictionary:
		flags = saved_flags.duplicate(true)

	current_room = String(cfg.get_value("run", "current_room", "main"))
	if RoomManager.get_room_scene(current_room) == null:
		current_room = "main"
	objective = String(cfg.get_value("run", "objective", "Uma página solta repousa sobre a estante."))
	play_time = float(cfg.get_value("run", "play_time", 0.0))

	monsters_seen.clear()
	var saved_seen: Variant = cfg.get_value("run", "monsters_seen", [])
	if saved_seen is Array:
		for raw in saved_seen:
			var id := String(raw)
			if ItemDB.MONSTERS.has(id):
				monsters_seen.append(id)

	selected_item = ""
	run_started = true
	_emit_all()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
