extends Node
## Autoload that swaps room scenes inside the running game, with a fade.
##
## Rooms are discovered from `res://scenes/rooms/` on first use. A room scene
## only needs a root with `room.gd` and a non-empty `room_id`. Add a new
## `.tscn` there and it is immediately available to doors (by path) and to the
## save system (by id).
##
## Doors normally call `go_to_path()` with the scene chosen in the inspector.

signal room_changed(room: Room)
signal transition_started
signal transition_finished

const ROOMS_DIR := "res://scenes/rooms/"
const FADE_OUT_TIME := 0.16
const FADE_IN_TIME := 0.22

var _host: Control
var _fade: ColorRect
var _current_room: Room
var _current_scene: PackedScene
var _history: Array[PackedScene] = []
var _changing := false
var _registry: Dictionary = {}
var _scanned := false


# ------------------------------------------------------------------ host
func register_host(host: Control, fade: ColorRect = null) -> void:
	_host = host
	_fade = fade
	_current_room = null
	_current_scene = null
	_history.clear()
	_changing = false
	if _fade != null:
		_fade.modulate.a = 0.0
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func unregister_host() -> void:
	_host = null
	_fade = null
	_current_room = null
	_current_scene = null
	_changing = false


func has_host() -> bool:
	return _host != null and is_instance_valid(_host)


func is_changing() -> bool:
	return _changing


func current_room_node() -> Room:
	return _current_room


func current_scene() -> PackedScene:
	return _current_scene


# ------------------------------------------------------------------ registry
func get_room_scene(room_id: String) -> PackedScene:
	if not _scanned:
		_scan_rooms()
	if not _registry.has(room_id):
		# Picks up a room added to the folder after the first scan.
		_scan_rooms()
	return _registry.get(room_id) as PackedScene


func list_room_ids() -> Array:
	if not _scanned:
		_scan_rooms()
	return _registry.keys()


func _scan_rooms() -> void:
	_scanned = true
	_registry.clear()

	var files := DirAccess.get_files_at(ROOMS_DIR)
	for file in files:
		if not file.ends_with(".tscn"):
			continue
		var path := ROOMS_DIR + file
		var scene := load(path) as PackedScene
		if scene == null:
			continue
		var probe := scene.instantiate()
		if probe == null:
			continue
		if probe.has_method("get_room_id"):
			var id := String(probe.get_room_id())
			if id != "":
				_registry[id] = scene
		probe.free()
	print("RoomManager: %d room scene(s) registered: %s" % [_registry.size(), _registry.keys()])


# ------------------------------------------------------------------ loading
## Replace the current room without a fade. Used for the initial room.
func load_immediate(scene: PackedScene, spawn_point: String = "") -> void:
	if scene == null or not has_host():
		return
	if _changing:
		return
	_set_room(scene, spawn_point)


## Change to a room scene by file path (the normal Door behaviour).
func go_to_path(path: String, spawn_point: String = "", remember := true) -> void:
	if path == "":
		return
	var scene := load(path) as PackedScene
	if scene == null:
		push_warning("RoomManager: could not load room scene '%s'." % path)
		return
	_transition(scene, spawn_point, remember)


## Change to a room by its `room_id` (optional Door mode).
func go_to_room(room_id: String, spawn_point: String = "", remember := true) -> void:
	var scene := get_room_scene(room_id)
	if scene == null:
		push_warning("RoomManager: no room scene registered for id '%s'." % room_id)
		return
	_transition(scene, spawn_point, remember)


func go_back() -> void:
	if _history.is_empty():
		return
	var scene: PackedScene = _history.pop_back()
	await _transition(scene, "", false)


func _transition(scene: PackedScene, spawn_point: String, remember: bool) -> void:
	if _changing or not has_host():
		return
	_changing = true
	transition_started.emit()

	await _fade_to(0.9, FADE_OUT_TIME)

	if remember and _current_scene != null:
		_history.append(_current_scene)
	_set_room(scene, spawn_point)

	await _fade_to(0.0, FADE_IN_TIME)

	_changing = false
	transition_finished.emit()


func _set_room(scene: PackedScene, spawn_point: String) -> void:
	if _current_room != null and is_instance_valid(_current_room):
		if _current_room.get_parent() == _host:
			_host.remove_child(_current_room)
		_current_room.queue_free()
	_current_room = null

	var node := scene.instantiate()
	if node == null:
		push_warning("RoomManager: failed to instantiate room scene.")
		return
	if not node is Room:
		push_warning("RoomManager: scene '%s' root does not use room.gd." % scene.resource_path)

	_host.add_child(node)
	_current_room = node as Room
	_current_scene = scene

	if _current_room != null:
		var id := _current_room.get_room_id() if _current_room.has_method("get_room_id") else ""
		if id != "":
			GameState.current_room = id
			GameState.save_game()
		if _current_room.has_method("emit_entered"):
			_current_room.emit_entered(spawn_point)
		room_changed.emit(_current_room)


func _fade_to(alpha: float, duration: float) -> void:
	if _fade == null or not is_instance_valid(_fade):
		return
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.5 else Control.MOUSE_FILTER_IGNORE
	var tween := _fade.create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, duration)
	await tween.finished


# ------------------------------------------------------------------ helpers
func refresh_current() -> void:
	if _current_room == null or not is_instance_valid(_current_room):
		return
	for node in get_tree().get_nodes_in_group("interactable"):
		if _current_room.is_ancestor_of(node) and node.has_method("refresh"):
			node.refresh()


func find_interactable(interaction_id: String) -> Interactable:
	if _current_room == null or not is_instance_valid(_current_room):
		return null
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is Interactable):
			continue
		if not _current_room.is_ancestor_of(node) or not node.visible:
			continue
		if node.interaction_id == interaction_id or node.name == interaction_id:
			return node
	return null


func clear_history() -> void:
	_history.clear()
