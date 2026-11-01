extends Node

func _ready() -> void:
	print("EMBEDDED ", Engine.is_embedded_in_editor())
	print("WINDOW ", get_window())
	get_tree().quit()
