class_name Room
extends Control
## Root of every room scene.
##
## Create a room by duplicating `scenes/rooms/room_template.tscn`, or any of
## the four example rooms. The only required things are:
##   Room Id       -> unique string (saved between runs)
##   Display Name  -> text shown in the HUD
##   Background    -> your art (TextureRect or the example painted backdrop)
##   Interactables -> a Control holding doors, pickups and examine hotspots
##
## Doors point to the .tscn file, so the game root does not need a hardcoded
## list of rooms. New room scenes are discovered automatically.

signal entered(spawn_point: String)

@export var room_id: String = ""
@export var display_name: String = ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := get_node_or_null("Backdrop")
	if backdrop != null and backdrop.has_method("set_room"):
		backdrop.set_room(room_id)


func get_room_id() -> String:
	return room_id


func get_display_name() -> String:
	return display_name


## Optional spawn marker. Add a Control named "Spawn_default", "Spawn_left",
## etc. anywhere in the room and point a Door to that name.
func get_spawn_point(spawn_point_name: String) -> Node:
	if spawn_point_name != "":
		var exact := find_child("Spawn_" + spawn_point_name, true, false)
		if exact != null:
			return exact
	return find_child("Spawn_default", true, false)


func emit_entered(spawn_point_name: String) -> void:
	entered.emit(spawn_point_name)
