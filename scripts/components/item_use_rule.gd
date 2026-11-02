class_name ItemUseRule
extends Resource
## One "use item on object" rule, editable in the inspector.
## Create these inside the `Use Rules` array of an Interactable.
##
## Example: using the bucket of water on the fireplace:
##   item_id = "bucket_water"
##   needs_selection = true
##   consume_selected = true
##   give_item = "sapphire"
##   set_flag = "fire_out"
##   message = "A água apaga a lareira e revela a safira."

@export_group("Item")
## Item id from ItemDB. Leave empty only for rules that should always match.
@export var item_id: String = ""
## If true, the item must be selected in the inventory.
## If false, it only needs to be somewhere in the inventory (useful for
## "light the dark room if you own a candle").
@export var needs_selection: bool = true

@export_group("Conditions")
## All of these flags must be true for the rule to run.
@export var required_flags: Array[String] = []
## None of these flags may be true for the rule to run.
@export var forbidden_flags: Array[String] = []

@export_group("Effects")
## Remove the selected item after using it.
@export var consume_selected: bool = false
## Remove this specific item after using the rule (for example, bait).
@export var consume_item: String = ""
## Add this item to the inventory after using the rule.
@export var give_item: String = ""
## Set this flag after using the rule.
@export var set_flag: String = ""
## Clear this flag after using the rule.
@export var clear_flag: String = ""
## Hide the object this rule belongs to (for one-use pickups/objects).
@export var consume_source: bool = false
## If set, the rule only pays out once. Later uses show `repeat_message`.
@export var once_flag: String = ""

@export_group("Feedback")
@export_multiline var message: String = ""
@export var speaker: String = ""
@export_multiline var repeat_message: String = ""
## Optional panel id handled by the game root: book, circle, keypad, diary.
@export var open_panel: String = ""
## Optional custom action id handled by the game root.
@export var action_id: String = ""
