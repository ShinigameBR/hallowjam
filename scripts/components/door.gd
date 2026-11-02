class_name Door
extends "res://scripts/components/interactable.gd"
## Attach this to a door image (TextureRect) and point it to another room
## scene in the inspector. No code needed per door.
##
## Destination can be set with:
##   Target Scene     -> a .tscn file (recommended)
##   Target Room Id   -> a room_id registered by a scene inside scenes/rooms/
##   Use Previous Room-> return to the room the player came from
##
## The `Label` field inherited from Interactable is the text shown on hover,
## for example "Porta da frente".

@export_group("Destination")
## Room scene to open. Use the file picker in the inspector.
@export_file("*.tscn") var target_scene: String = ""
## Optional alternative: the `room_id` exported by another room scene.
@export var target_room_id: String = ""
## Go back through the room history instead of using a fixed destination.
@export var use_previous_room: bool = false
## Optional spawn marker name inside the destination room (Spawn_<name>).
@export var spawn_point: String = "default"

@export_group("Lock")
## Keep the door closed until the conditions below are met.
@export var locked: bool = false
## Item the player must select before clicking the door.
@export var required_item: String = ""
## Remove the required item when it unlocks the door.
@export var consume_key: bool = false
## Optional world flag that must be true before the door opens.
@export var required_flag: String = ""
## Optional clue flag written the first time the player finds this door
## locked. Use it to unlock hints elsewhere (for example, the hidden key).
@export var clue_flag: String = ""
## Flag written when the door is unlocked. Keeps it open after a reload.
@export var unlock_flag: String = ""
@export_multiline var locked_message: String = "Está trancada."
@export_multiline var unlock_message: String = ""


func _on_interact(selected_item: String) -> void:
	if _is_locked(selected_item):
		return

	if unlock_message != "":
		GameState.notify(unlock_message)

	GameState.clear_selection()

	if use_previous_room:
		RoomManager.go_back()
		return

	if target_room_id != "":
		RoomManager.go_to_room(target_room_id, spawn_point)
		return

	if target_scene == "":
		push_warning("Door '%s' has no target scene or room id." % name)
		return

	RoomManager.go_to_path(target_scene, spawn_point)


## Returns true when the door should stay closed.
func _is_locked(selected_item: String) -> bool:
	if unlock_flag != "" and GameState.has_flag(unlock_flag):
		return false

	var needs_condition := locked or required_item != "" or required_flag != ""

	if not needs_condition:
		return false

	if clue_flag != "" and not GameState.has_flag(clue_flag):
		GameState.set_flag(clue_flag)
		GameState.save_game()

	if required_flag != "" and not GameState.has_flag(required_flag):
		say(locked_message)
		return true

	if required_item != "":
		if selected_item != required_item:
			say(locked_message)
			return true
		if consume_key:
			GameState.remove_item(required_item)
		if unlock_flag != "":
			GameState.set_flag(unlock_flag)
		GameState.clear_selection()
		GameState.save_game()
		return false

	# `locked` without a key/flag condition is a permanently sealed door.
	say(locked_message)
	return true
