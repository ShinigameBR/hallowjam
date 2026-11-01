extends Node
## User preferences, persisted separately from the run save.

const PATH := "user://settings.cfg"

var master_volume: float = 0.8
var fullscreen: bool = false


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = clampf(float(cfg.get_value("audio", "master", 0.8)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	save_settings()


func set_fullscreen(value: bool) -> void:
	if is_embedded():
		fullscreen = false
		return
	fullscreen = value
	_apply_video()
	save_settings()


func is_embedded() -> bool:
	return Engine.is_embedded_in_editor()


func window_is_fullscreen() -> bool:
	if DisplayServer.get_name() == "headless":
		return fullscreen
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func apply() -> void:
	_apply_audio()
	_apply_video()


func _apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.001)))


func _apply_video() -> void:
	if DisplayServer.get_name() == "headless" or is_embedded():
		return
	var win := get_window()
	if win != null:
		win.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
