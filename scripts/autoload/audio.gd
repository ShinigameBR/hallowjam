extends Node
## Global audio layer.
##
## Two looping tracks carry the mood (menu and gameplay) and a small pool of
## players handles short effects. Every sound is synthesized by
## tools/generate_audio.py; there are no external samples.
##
## Music loops are patched at runtime because the WAV importer ignores the
## loop settings in this project.

const MUSIC_DB := -9.0
const SFX_DB := -7.0
const SFX_VOICES := 20

const TRACKS := {
	"menu": preload("res://assets/audio/menu_theme.wav"),
	"game": preload("res://assets/audio/game_ambience.wav"),
}

const SFX := {
	"click": preload("res://assets/audio/click.wav"),
	"dial": preload("res://assets/audio/dial.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"place": preload("res://assets/audio/place.wav"),
	"page": preload("res://assets/audio/page.wav"),
	"unlock": preload("res://assets/audio/unlock.wav"),
	"summon": preload("res://assets/audio/summon.wav"),
	"ending": preload("res://assets/audio/ending.wav"),
	"error": preload("res://assets/audio/error.wav"),
	"dialog": preload("res://assets/audio/dialog.wav"),
	"door": preload("res://assets/audio/door.wav"),
	"gem": preload("res://assets/audio/gem.wav"),
	"metal": preload("res://assets/audio/metal.wav"),
	"water": preload("res://assets/audio/water.wav"),
	"wood": preload("res://assets/audio/wood.wav"),
	"leaf": preload("res://assets/audio/leaf.wav"),
	"music_box": preload("res://assets/audio/music_box.wav"),
	"summon_carmesim": preload("res://assets/audio/summon_carmesim.wav"),
	"summon_branco": preload("res://assets/audio/summon_branco.wav"),
	"summon_azul": preload("res://assets/audio/summon_azul.wav"),
	"summon_none": preload("res://assets/audio/summon_none.wav"),
	"fire": preload("res://assets/audio/fire.wav"),
}

## Item-specific sounds. Anything missing falls back to the item's tags.
const ITEM_SFX := {
	"music_box": "music_box",
	"ruby": "gem",
	"sapphire": "gem",
	"pearl": "gem",
	"escama_azul": "gem",
	"oyster": "water",
	"fish": "water",
	"water": "water",
	"water_syringe": "water",
	"bucket_water": "water",
	"potion": "water",
	"key": "metal",
	"screwdriver": "metal",
	"knife": "metal",
	"sardines": "metal",
	"bucket": "metal",
	"stone": "metal",
	"lavender": "leaf",
	"lavender_revived": "leaf",
	"mushroom": "leaf",
	"bait": "leaf",
	"diary": "page",
	"book_page": "page",
	"suitcase": "wood",
	"fish_bone": "wood",
}

const TAG_SFX := [
	["music", "music_box"],
	["gem", "gem"],
	["valuable", "gem"],
	["water", "water"],
	["liquid", "water"],
	["ocean", "water"],
	["metal", "metal"],
	["sharp", "metal"],
	["plant", "leaf"],
	["floral", "leaf"],
	["paper", "page"],
	["knowledge", "page"],
	["wood", "wood"],
]

const DIAL_BUTTONS := ["Red", "Blue", "Yellow", "Green", "SunDial", "MoonDial"]

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _current_track := ""
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _last_inventory: Array[String] = []
var _last_dialog_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_a = _make_player()
	_music_b = _make_player()
	for index in SFX_VOICES:
		_sfx_players.append(_make_player())

	_last_inventory = _inventory_ids()
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.dialogue_requested.connect(_on_dialogue_requested)
	get_tree().node_added.connect(_on_node_added)


func _make_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	add_child(player)
	return player


# ------------------------------------------------------------------- music
func play_music(track_id: String, fade: float = 1.2) -> void:
	if track_id == _current_track and _active_music != null and _active_music.playing:
		return
	if not TRACKS.has(track_id):
		push_warning("Unknown music track '%s'." % track_id)
		return

	var next_player: AudioStreamPlayer = _music_a if _active_music != _music_b else _music_b
	var old_player := _active_music
	_active_music = next_player
	_current_track = track_id

	next_player.stream = _looped(TRACKS[track_id])
	next_player.volume_db = -60.0 if fade > 0.0 else MUSIC_DB
	next_player.play()

	if fade <= 0.0:
		if old_player != null:
			old_player.stop()
		return

	var fade_in := create_tween()
	fade_in.tween_property(next_player, "volume_db", MUSIC_DB, fade)

	if old_player != null and old_player != next_player:
		var fade_out := create_tween()
		fade_out.tween_property(old_player, "volume_db", -60.0, fade)
		fade_out.tween_callback(old_player.stop)


func stop_music(fade: float = 1.0) -> void:
	_current_track = ""
	var player := _active_music
	_active_music = null
	if player == null:
		return
	if fade <= 0.0:
		player.stop()
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, fade)
	tween.tween_callback(player.stop)


## Wraps a music stream so it loops forever, even when the import left the
## loop disabled. Returns the source untouched when it already loops.
func _looped(source: AudioStream) -> AudioStream:
	var wav := source as AudioStreamWAV
	if wav == null or wav.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return source
	var copy: AudioStreamWAV = wav.duplicate()
	copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
	copy.loop_begin = 0
	copy.loop_end = int(round(copy.get_length() * copy.mix_rate))
	return copy


# --------------------------------------------------------------------- sfx
func play_sfx(sfx_id: String, volume_offset: float = 0.0) -> void:
	var stream: AudioStream = SFX.get(sfx_id)
	if stream == null:
		return
	var player := _take_player()
	player.stream = stream
	player.volume_db = SFX_DB + volume_offset
	player.play()


## Plays the sound that fits an item: its own entry first, then its tags.
func play_item(item_id: String, volume_offset: float = 0.0) -> void:
	play_sfx(item_sfx(item_id), volume_offset)


func item_sfx(item_id: String) -> String:
	if ITEM_SFX.has(item_id):
		return String(ITEM_SFX[item_id])
	var tags := ItemDB.item_tags(item_id)
	for entry in TAG_SFX:
		if tags.has(entry[0]):
			return String(entry[1])
	return "pickup"


func summon_sfx(monster_id: String) -> void:
	match monster_id:
		"carmesim":
			play_sfx("summon_carmesim", 1.0)
		"branco":
			play_sfx("summon_branco", 1.0)
		"azul":
			play_sfx("summon_azul", 1.0)
		_:
			play_sfx("summon_none", -1.0)


func _take_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	var picked := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	picked.stop()
	return picked


# ------------------------------------------------------------------- hooks
func _inventory_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in GameState.inventory:
		ids.append(String(id))
	return ids


func _on_inventory_changed() -> void:
	var current := _inventory_ids()
	var added: Array[String] = []
	for id in current:
		if not _last_inventory.has(id):
			added.append(id)

	if added.size() == 1:
		play_item(added[0], -1.0)
	elif added.size() > 1:
		play_sfx("place", 1.0)
	elif current.size() < _last_inventory.size():
		play_sfx("place", 1.0)

	_last_inventory = current


func _on_dialogue_requested(_lines: Array) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_dialog_ms < 90:
		return
	_last_dialog_ms = now
	play_sfx("dialog", -2.0)


func _on_node_added(node: Node) -> void:
	if not (node is BaseButton):
		return
	if node.has_meta("audio_click") or node.has_meta("audio_click_mute"):
		return
	node.set_meta("audio_click", true)
	var button := node as BaseButton
	if _is_dial_button(button):
		button.pressed.connect(play_sfx.bind("dial", -3.0))
	else:
		button.pressed.connect(play_sfx.bind("click", -5.0))


func _is_dial_button(button: BaseButton) -> bool:
	var node_name := str(button.name)
	return node_name.begins_with("Dial") or DIAL_BUTTONS.has(node_name)
