class_name Examine
extends "res://scripts/components/interactable.gd"
## A generic clickable object: examine it, open a panel, set a flag, give an
## item, or send a custom action to the game root.
##
## Most puzzle reactions (use the potion on the lavender, use the bucket of
## water on the fireplace, feed the fish to the Carmesim) are configured with
## the `Use Rules` array inherited from Interactable.

@export_group("Examine")
@export_multiline var message: String = ""
@export var speaker: String = ""
## Shown when the player clicks with an unrelated selected item.
@export_multiline var wrong_item_message: String = "Nada acontece."
## Ignore the selected inventory item instead of blocking the click. Useful
## for objects that always open a panel, like the ritual circle.
@export var ignore_selected_item: bool = false

@export_group("Effects")
## Custom id handled by the game root (`_on_action`).
@export var action_id: String = ""
## Panel opened by the game root: book, circle, keypad or diary.
@export var open_panel: String = ""
## Flag written after a normal (no item) click.
@export var set_flag: String = ""
## Item added after a normal (no item) click.
@export var give_item: String = ""
## If set, effects only run once. Later clicks show `repeat_message`.
@export var once_flag: String = ""
@export_multiline var repeat_message: String = ""

@export_group("Conditions")
## Only works after this flag is true.
@export var required_flag: String = ""
@export_multiline var blocked_message: String = ""


func _on_interact(selected_item: String) -> void:
	if selected_item != "" and not ignore_selected_item:
		say(wrong_item_message)
		return

	if required_flag != "" and not GameState.has_flag(required_flag):
		say(blocked_message if blocked_message != "" else "Ainda não.")
		return

	if once_flag != "" and GameState.has_flag(once_flag):
		say(repeat_message if repeat_message != "" else message, speaker)
		return

	if action_id != "":
		GameState.action_requested.emit(action_id, self)
	if open_panel != "":
		GameState.panel_requested.emit(open_panel)
	if set_flag != "":
		GameState.set_flag(set_flag)
	if give_item != "":
		GameState.add_item(give_item)
	if message != "":
		say(message, speaker)
	if once_flag != "":
		GameState.set_flag(once_flag)

	if action_id != "" or open_panel != "" or set_flag != "" or give_item != "" or once_flag != "":
		GameState.save_game()
