class_name ItemPickup
extends "res://scripts/components/interactable.gd"
## Attach this to an item image. Clicking it adds the item to the inventory.
##
## The item id must exist in `scripts/autoload/item_db.gd`. The label is
## filled automatically with the item name when left empty.
##
## Example:
##   Item Id      = "feather"
##   Pickup Flag  = "picked_feather"   (auto-filled if empty)
##   Description  = "Uma pena presa na janela..."

@export_group("Pickup")
## Item id from ItemDB. Must exist there.
@export var item_id: String = ""
## World flag written after the pickup. Auto-filled as "picked_<item_id>".
@export var pickup_flag: String = ""
## Text shown when the item is collected.
@export_multiline var description: String = ""
## Hide this object after it is collected.
@export var hide_after_pickup: bool = true

@export_group("Conditions")
## Only collectable after this flag is true. Leave empty for always.
@export var required_flag: String = ""
## Text shown when `required_flag` is not met.
@export_multiline var blocked_message: String = ""
## Text shown when the player clicks with an unrelated item selected.
@export_multiline var wrong_item_message: String = "Nada acontece."
## Text shown when the item was already collected.
@export_multiline var already_message: String = "Você já pegou isso."


func _ready_extra() -> void:
	if pickup_flag == "" and item_id != "":
		pickup_flag = "picked_" + item_id
	if label == "" and item_id != "":
		label = ItemDB.item_name(item_id)
		tooltip_text = label if _debug_hover_enabled() else ""
	if hide_after_pickup and pickup_flag != "" and not hide_when_flags.has(pickup_flag):
		hide_when_flags.append(pickup_flag)
	refresh()


func _on_interact(selected_item: String) -> void:
	if item_id == "":
		push_warning("ItemPickup '%s' has no item_id." % name)
		return

	if selected_item != "":
		say(wrong_item_message)
		return

	if required_flag != "" and not GameState.has_flag(required_flag):
		say(blocked_message if blocked_message != "" else "Ainda não.")
		return

	if pickup_flag != "" and GameState.has_flag(pickup_flag):
		say(already_message)
		return

	if not ItemDB.ITEMS.has(item_id):
		push_warning("ItemPickup '%s' uses unknown item id '%s'." % [name, item_id])
		return

	GameState.add_item(item_id)
	if pickup_flag != "":
		GameState.set_flag(pickup_flag)
	GameState.clear_selection()
	GameState.save_game()

	var text := description
	if text == "":
		text = "Você pega %s." % ItemDB.item_name(item_id)
	say(text)

	if hide_after_pickup:
		_consume_source()
