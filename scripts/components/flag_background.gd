extends TextureRect
## Fundo que troca de imagem quando uma flag fica verdadeira.
## Ex.: o cais com o buraco fechado vira o cais com o buraco cavado.
##
## No Inspector: Texture é a imagem normal, Texture When Flag é a imagem
## usada enquanto a Flag estiver ligada.

## Flag que troca a imagem.
@export var flag: String = ""
## Imagem usada enquanto a flag estiver verdadeira.
@export var texture_when_flag: Texture2D

var _default_texture: Texture2D


func _ready() -> void:
	_default_texture = texture
	GameState.flags_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if flag != "" and texture_when_flag != null and GameState.has_flag(flag):
		texture = texture_when_flag
	else:
		texture = _default_texture
