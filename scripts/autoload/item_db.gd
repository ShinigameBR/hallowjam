extends Node
## All item and monster data lives here. Keeping it in one place makes it
## trivial to rebalance the ritual during a jam.

const TARGET := "carmesim"

const TAG_NAMES := {
	"poison": "venenoso",
	"smelly": "cheiro forte",
	"plant": "planta",
	"ocean": "oceano",
	"water": "água",
	"liquid": "líquido",
	"food": "comida",
	"wind": "vento",
	"hard": "duro",
	"resistant": "resistente",
	"lazy": "preguiçoso",
	"fish": "peixe",
	"red": "vermelho",
	"floral": "floral",
	"solitary": "solitário",
	"feelings": "sentimentos",
	"light": "luz",
	"fire": "fogo",
	"sharp": "afiado",
	"tool": "ferramenta",
	"blood": "sangue",
	"sleep": "sono",
	"knowledge": "conhecimento",
	"music": "música",
	"bird": "ave",
	"soft": "macio",
	"wood": "madeira",
	"metal": "metal",
	"wax": "cera",
	"flesh": "carne",
	"paper": "papel",
	"monster": "monstruoso",
	"giant": "gigante",
	"gem": "gema",
	"key": "chave",
	"healing": "cura",
	"purple": "roxo",
	"shell": "concha",
	"worm": "verme",
	"valuable": "valioso",
	"blue": "azul",
}

var ITEMS := {
	"mushroom": {
		"name": "Cogumelo Pálido",
		"desc": "Cresce nas frestas úmidas da parede. Cheira a terra e a algo doce demais.",
		"tags": ["poison", "smelly", "plant"],
		"color": Color("#b58ad6"),
		"icon": "mushroom",
		"kind": "ingredient",
	},
	"moss": {
		"name": "Musgo da Parede",
		"desc": "Um tufo macio, com pequenas flores brancas presas entre os fios.",
		"tags": ["plant", "floral", "soft"],
		"color": Color("#6fae6a"),
		"icon": "moss",
		"kind": "ingredient",
	},
	"algae": {
		"name": "Alga Viscosa",
		"desc": "Escorregadia, salgada, viva. Ainda guarda água do mar por dentro.",
		"tags": ["ocean", "water", "plant", "smelly"],
		"color": Color("#4e9c7a"),
		"icon": "algae",
		"kind": "ingredient",
	},
	"feather": {
		"name": "Pena de Gaivota",
		"desc": "Leve como um pensamento. Ainda se move quando não há vento.",
		"tags": ["wind", "bird", "light"],
		"color": Color("#d8d4c8"),
		"icon": "feather",
		"kind": "ingredient",
	},
	"flower": {
		"name": "Flor Carmesim",
		"desc": "Uma flor teimosa, vermelha como uma ferida recente.",
		"tags": ["floral", "red", "plant"],
		"color": Color("#c8556a"),
		"icon": "flower",
		"kind": "ingredient",
	},
	"shell": {
		"name": "Concha Solitária",
		"desc": "Uma espiral dura e vazia. Nenhum outro bicho escolheu morar aqui.",
		"tags": ["ocean", "hard", "solitary", "shell"],
		"color": Color("#c9b9a0"),
		"icon": "shell",
		"kind": "ingredient",
	},
	"stone": {
		"name": "Pedra do Cais",
		"desc": "Pesada, fria, coberta de limo. Não se importa com nada.",
		"tags": ["hard", "resistant"],
		"color": Color("#8d8f94"),
		"icon": "stone",
		"kind": "ingredient",
	},
	"fish": {
		"name": "Peixe Fresco",
		"desc": "Ainda debate. O mar não perdoa quem sai da água.",
		"tags": ["fish", "food", "ocean"],
		"color": Color("#7fb3c9"),
		"icon": "fish",
		"kind": "ingredient",
	},
	"sardines": {
		"name": "Lata de Sardinha",
		"desc": "Comida de humano, preservada em óleo. A lata está enferrujada.",
		"tags": ["fish", "food", "hard", "lazy", "metal"],
		"color": Color("#b7a06a"),
		"icon": "can",
		"kind": "ingredient",
	},
	"meat": {
		"name": "Carne Crua",
		"desc": "Um pedaço generoso. Ainda quente. Você prefere não pensar de onde veio.",
		"tags": ["food", "flesh", "feelings"],
		"color": Color("#b0525e"),
		"icon": "meat",
		"kind": "ingredient",
	},
	"water": {
		"name": "Água Salgada",
		"desc": "Um pouco de mar numa garrafa quebrada. Cheira a tempestade.",
		"tags": ["liquid", "water"],
		"color": Color("#6fa8c9"),
		"icon": "water",
		"kind": "ingredient",
	},
	"water_syringe": {
		"name": "Seringa com Água",
		"desc": "Água salgada dentro de uma seringa. Não é exatamente higiênico.",
		"tags": ["liquid", "water"],
		"color": Color("#6fa8c9"),
		"icon": "syringe_water",
		"kind": "ingredient",
	},
	"potion": {
		"name": "Poção",
		"desc": "Um líquido violeta que parece olhar de volta.",
		"tags": ["liquid", "purple"],
		"color": Color("#8d6bc9"),
		"icon": "potion",
		"kind": "ingredient",
		"texture": "res://assets/props/pocao.png",
	},
	"tranq": {
		"name": "Seringa com Tranquilizante",
		"desc": "A poção violeta, agora na dose certa para derrubar algo grande.",
		"tags": ["liquid", "sleep", "tool"],
		"color": Color("#7fb6c9"),
		"icon": "syringe_tranq",
		"kind": "tool",
	},
	"blood": {
		"name": "Seringa com Sangue",
		"desc": "O seu. Quente, vermelho e cheio de coisas que você não diz em voz alta.",
		"tags": ["liquid", "blood", "red", "feelings"],
		"color": Color("#a83b4a"),
		"icon": "syringe_blood",
		"kind": "ingredient",
	},
	"monster_fluid": {
		"name": "Seringa com Líquido Viscoso",
		"desc": "Extraído do barril do porão. Ferve baixinho quando você a sacode.",
		"tags": ["liquid", "poison", "monster"],
		"color": Color("#7a8f4e"),
		"icon": "syringe_monster",
		"kind": "ingredient",
	},
	"syringe": {
		"name": "Seringa Vazia",
		"desc": "Uma seringa de vidro, grande o bastante para extrair quase qualquer coisa.",
		"tags": ["tool", "metal"],
		"color": Color("#b9c4cc"),
		"icon": "syringe_empty",
		"kind": "tool",
	},
	"knife": {
		"name": "Faca de Cozinha",
		"desc": "Afiada. Serve para cortar ervas, peixes e outras coisas menos agradáveis.",
		"tags": ["sharp", "tool", "metal"],
		"color": Color("#c3c9cf"),
		"icon": "knife",
		"kind": "tool",
	},
	"rod": {
		"name": "Vara de Pescar",
		"desc": "Velha, mas ainda serve para pescar.",
		"tags": ["tool", "wood"],
		"color": Color("#b08a5a"),
		"icon": "rod",
		"kind": "tool",
		"texture": "res://assets/props/vara_desativada.png",
	},
	"music_box": {
		"name": "Caixa de Música",
		"desc": "Toca uma valsa que você conhece de algum lugar. O ar fica mais leve perto dela.",
		"tags": ["music", "wind", "feelings"],
		"color": Color("#c9a35e"),
		"icon": "music_box",
		"kind": "ingredient",
	},
	"diary": {
		"name": "Diário do Bruxo",
		"desc": "A letra é apertada, raivosa. As últimas páginas falam de um ritual de fuga.",
		"tags": ["knowledge", "feelings", "paper"],
		"color": Color("#b8a06a"),
		"icon": "diary",
		"kind": "clue",
	},
	"candle": {
		"name": "Vela de Sebo",
		"desc": "Uma chama pequena, mas teimosa. Cheira a cera e a igreja antiga.",
		"tags": ["light", "fire", "wax"],
		"color": Color("#e0c07a"),
		"icon": "candle",
		"kind": "tool",
	},
	"bucket": {
		"name": "Balde",
		"desc": "Um balde vazio.",
		"tags": ["tool", "wood"],
		"color": Color("#9aa0a6"),
		"icon": "bucket",
		"kind": "tool",
		"texture": "res://assets/props/balde.png",
	},
	"bucket_water": {
		"name": "Balde com Água",
		"desc": "Balde cheio de água.",
		"tags": ["tool", "water", "liquid"],
		"color": Color("#6fa8c9"),
		"icon": "bucket",
		"kind": "tool",
	},
	"screwdriver": {
		"name": "Chave de Fenda",
		"desc": "Uma chave de fenda velha.",
		"tags": ["tool", "metal", "sharp"],
		"color": Color("#b9c4cc"),
		"icon": "stone",
		"kind": "tool",
		"texture": "res://assets/props/chave_de_fenda.png",
	},
	"sapphire": {
		"name": "Safira",
		"desc": "Uma joia azul.",
		"tags": ["gem", "valuable", "blue"],
		"color": Color("#6d9fd1"),
		"icon": "stone",
		"kind": "clue",
		"texture": "res://assets/props/safira.png",
	},
	"ruby": {
		"name": "Rubi",
		"desc": "Uma joia vermelha.",
		"tags": ["gem", "valuable", "red"],
		"color": Color("#cf5d63"),
		"icon": "stone",
		"kind": "clue",
		"texture": "res://assets/props/rubi.png",
	},
	"lavender": {
		"name": "Lavanda Murcha",
		"desc": "Uma flor violeta murcha.",
		"tags": ["plant", "floral", "purple"],
		"color": Color("#a488d6"),
		"icon": "flower",
		"kind": "ingredient",
		"texture": "res://assets/props/flor_murcha.png",
	},
	"lavender_revived": {
		"name": "Lavanda Revivida",
		"desc": "Uma flor violeta que exala um aroma floral.",
		"tags": ["plant", "floral", "purple"],
		"color": Color("#b58ad6"),
		"icon": "flower",
		"kind": "ingredient",
		"texture": "res://assets/props/flor_revivida.png",
	},
	"bait": {
		"name": "Minhoca",
		"desc": "Uma minhoca gorda, ainda se contorcendo. Serve de isca.",
		"tags": ["food", "worm", "smelly"],
		"color": Color("#b7a06a"),
		"icon": "mushroom",
		"kind": "ingredient",
	},
	"suitcase": {
		"name": "Maleta",
		"desc": "Uma maleta de couro trancada. Dois encaixes esperam por ponteiros: um marcado com o sol, outro com a lua.",
		"tags": ["tool", "wood", "key"],
		"color": Color("#8a6a4a"),
		"icon": "diary",
		"kind": "clue",
	},
	"key": {
		"name": "Chave",
		"desc": "Uma chave enferrujada.",
		"tags": ["key", "metal"],
		"color": Color("#c3c9cf"),
		"icon": "stone",
		"kind": "clue",
	},
	"pearl": {
		"name": "Pérola",
		"desc": "Uma pérola lustrosa.",
		"tags": ["gem", "valuable", "ocean"],
		"color": Color("#e8e3d4"),
		"icon": "stone",
		"kind": "clue",
	},
	"oyster": {
		"name": "Ostra",
		"desc": "Uma ostra fechada.",
		"tags": ["ocean", "food", "shell"],
		"color": Color("#c9b9a0"),
		"icon": "shell",
		"kind": "ingredient",
	},
}

var MONSTERS := {
	"verde": {
		"name": "O Errante Verde",
		"title": "Guia das marés",
		"color": Color("#6fbf8a"),
		"recipe": ["food", "wind", "water"],
		"hints": [
			"Uma comida que os humanos adoram.",
			"Algo ligado ao vento.",
			"Algo com grande teor de água.",
		],
		"desc": "Um anfíbio desengonçado, de olhos grandes e dedos longos. Não parece perigoso. Parece que estava esperando por você.",
		"ability": "Conhece as correntes e pode te levar em segurança até a costa.",
		"victory": true,
	},
	"azul": {
		"name": "O Cego das Profundezas",
		"title": "Predador abissal",
		"color": Color("#6d9fd1"),
		"recipe": ["ocean", "smelly", "solitary"],
		"hints": [
			"Algo relacionado ao oceano.",
			"Algo com um cheiro forte.",
			"Algo de natureza solitária.",
		],
		"desc": "Uma coisa azul e faminta, com garras longas e nenhum olho. Só se sente em casa no fundo do mar.",
		"ability": "Nada rápido demais. Não enxerga nada acima da água.",
		"victory": false,
	},
	"vermelho": {
		"name": "A Ilha Vermelha",
		"title": "Carapaça viva",
		"color": Color("#cf5d63"),
		"recipe": ["giant"],
		"hints": [
			"Algo enorme.",
		],
		"desc": "Uma massa enorme de carapaça e músculo. Move-se uma vez a cada respiração e já parece tarde demais.",
		"ability": "Quase impenetrável. Quase inútil quando algo dá errado.",
		"victory": false,
	},
	"carmesim": {
		"name": "O Beija-Flor Carmesim",
		"title": "Mensageiro fiel",
		"color": Color("#c2445f"),
		"recipe": ["red", "floral"],
		"hints": [
			"Algo vermelho.",
			"Alguma coisa floral.",
		],
		"desc": "Pequeno, rápido e barulhento. Bate as asas tão depressa que o ar parece vibrar.",
		"ability": "Leal a quem o alimenta. Abre passagem para o sótão.",
		"victory": true,
	},
	"roxo": {
		"name": "O Sapo Venenoso",
		"title": "Barulho e veneno",
		"color": Color("#a488d6"),
		"recipe": ["poison", "liquid"],
		"hints": [
			"Algo venenoso.",
			"Qualquer líquido.",
		],
		"desc": "Um sapo pequeno e úmido. Coaxa sem parar e deixa um rastro que queima a garganta.",
		"ability": "Fácil de invocar. Difícil de suportar.",
		"victory": false,
	},
	"branco": {
		"name": "A Luz que Escuta",
		"title": "Consciência emprestada",
		"color": Color("#e8e3d4"),
		"recipe": ["feelings", "ocean"],
		"hints": [
			"Algo que contenha sentimentos.",
			"Algo ligado ao oceano.",
		],
		"desc": "Uma forma branca, quase sem contorno. Ela não fala: você simplesmente entende.",
		"ability": "Brilha forte e enxerga o que você tenta esconder. Não luta.",
		"victory": false,
	},
	"none": {
		"name": "Nada",
		"title": "Fumaça e sal",
		"color": Color("#5d6879"),
		"recipe": [],
		"hints": [],
		"desc": "O círculo acende, treme, e apaga. Nenhuma criatura atende ao chamado.",
		"ability": "Talvez falte alguma coisa. Ou talvez sobre.",
		"victory": false,
	},
}


func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})


func monster(id: String) -> Dictionary:
	return MONSTERS.get(id, MONSTERS["none"])


func item_name(id: String) -> String:
	return String(ITEMS.get(id, {}).get("name", id))


func item_color(id: String) -> Color:
	return ITEMS.get(id, {}).get("color", UI.MUTED)


func item_tags(id: String) -> Array:
	return ITEMS.get(id, {}).get("tags", [])


func tags_text(tags: Array) -> String:
	var parts: Array[String] = []
	for tag in tags:
		parts.append(String(TAG_NAMES.get(tag, tag)))
	return " · ".join(parts)


func collect_tags(item_ids: Array) -> Dictionary:
	var found := {}
	for id in item_ids:
		if id == "":
			continue
		for tag in item_tags(id):
			found[tag] = true
	return found


func has_all_tags(tags: Dictionary, required: Array) -> bool:
	for tag in required:
		if not tags.has(tag):
			return false
	return true


func resolve_summon(item_ids: Array) -> String:
	var tags := collect_tags(item_ids)
	if tags.is_empty():
		return "none"

	# The creature written in the book always wins when its recipe is met.
	if has_all_tags(tags, MONSTERS[TARGET]["recipe"]):
		return TARGET

	var priority := ["roxo", "carmesim", "azul", "vermelho", "branco"]
	for id in priority:
		if has_all_tags(tags, MONSTERS[id]["recipe"]):
			return id
	return "none"


func recipe_text(monster_id: String) -> String:
	var req: Array = MONSTERS.get(monster_id, {}).get("recipe", [])
	var parts: Array[String] = []
	for tag in req:
		parts.append(String(TAG_NAMES.get(tag, tag)))
	return " + ".join(parts)
