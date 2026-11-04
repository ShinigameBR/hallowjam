extends "res://scripts/game/overlay.gd"
## Result card shown after the ritual resolves. Offerings are only consumed
## on a successful summon; the game handles returning them on failure.

signal finished(victory: bool)

const GLYPH := preload("res://scripts/game/monster_glyph.gd")
const CARMESIM_ART := preload("res://assets/props/monstro_carmesim.png")

var _monster_id := "none"
var _victory := false
var _acting := false
var _eyebrow: Label
var _name: Label
var _title: Label
var _desc: Label
var _ability: Label
var _action: Button
var _glyph: Control
var _portrait: TextureRect


func _build() -> void:
	panel.custom_minimum_size = Vector2(620, 0)

	_eyebrow = UI.label("O CÍRCULO RESPONDE", "Eyebrow")
	_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_eyebrow)

	_portrait = TextureRect.new()
	_portrait.texture = CARMESIM_ART
	_portrait.custom_minimum_size = Vector2(140, 226)
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.visible = false
	body.add_child(_portrait)

	_glyph = GLYPH.new()
	_glyph.setup("none")
	_glyph.custom_minimum_size = Vector2(230, 230)
	_glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(_glyph)

	_name = UI.label("", "H1")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_name)

	_title = UI.label("", "EyebrowMuted")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_title)

	body.add_child(UI.spacer(4))
	body.add_child(UI.hline(Color(UI.ACCENT, 0.24), 1))
	body.add_child(UI.spacer(4))

	_desc = UI.label("", "BodyLarge")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc.custom_minimum_size = Vector2(520, 0)
	body.add_child(_desc)

	body.add_child(UI.spacer(4))

	var ability_panel := UI.panel("PagePanel")
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	ability_panel.add_child(margin)
	_ability = UI.label("", "Muted")
	_ability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability.custom_minimum_size = Vector2(480, 0)
	margin.add_child(_ability)
	body.add_child(ability_panel)

	body.add_child(UI.spacer(6))

	_action = UI.button("RECOLHER OFERENDAS", "PrimaryButton")
	_action.custom_minimum_size = Vector2(260, 46)
	_action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_action.pressed.connect(_on_action)
	body.add_child(_action)


func show_result(monster_id: String) -> void:
	_monster_id = monster_id
	_acting = false
	var data := ItemDB.monster(monster_id)
	_victory = bool(data.get("victory", false))
	var is_carmesim := monster_id == "carmesim"
	_portrait.visible = is_carmesim
	_glyph.visible = not is_carmesim
	_glyph.setup(monster_id)
	_name.text = String(data.get("name", "Nada"))
	_title.text = String(data.get("title", ""))
	_desc.text = String(data.get("desc", ""))
	_ability.text = String(data.get("ability", ""))
	_eyebrow.text = "O CÍRCULO RESPONDE" if monster_id != "none" else "SILÊNCIO"
	_action.text = "PARTIR" if _victory else "RECOLHER OFERENDAS"
	if monster_id == "branco":
		_action.text = "SEGUIR A LUZ"
	elif monster_id == "azul":
		_action.text = "ENFRENTAR"
	open()


func _on_action() -> void:
	if _acting:
		return
	_acting = true
	var was_victory := _victory
	await close()
	finished.emit(was_victory)


## ESC and clicks on the dim layer confirm the result instead of silently
## dismissing it, so the offerings are always resolved.
func dismiss() -> void:
	_on_action()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_action()
