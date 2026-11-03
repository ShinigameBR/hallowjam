# Criando itens, receitas e monstros

Os itens e as criaturas do ritual ficam em um único autoload:
`scripts/autoload/item_db.gd`. Ele é a fonte de verdade para nome, descrição,
tags, cor, ícone e receitas. Nenhuma sala precisa repetir esses dados: o
`ItemPickup` só guarda o **id** do item.

> Para criar a sala e o hotspot que entrega o item, veja
> [CRIANDO_SALAS.md](CRIANDO_SALAS.md). Para os textos, veja
> [ESCREVENDO_TEXTOS.md](ESCREVENDO_TEXTOS.md).

## O que é um item

Cada entrada de `ITEMS` é um `Dictionary` com estes campos:

| Campo | Obrigatório? | Para que serve |
| --- | --- | --- |
| `name` | sim | Nome exibido no inventário, no círculo e nas mensagens. |
| `desc` | sim | Descrição do item (tooltip/inspeção). |
| `tags` | sim | Qualidades usadas pelas receitas do ritual. |
| `color` | sim | Cor do ícone vetorial e do brilho do item. |
| `icon` | sim | Nome do desenho vetorial em `item_icon.gd`. |
| `kind` | não | Rótulo organizacional: `ingredient`, `tool`, `clue`, etc. |
| `texture` | não | Caminho de uma PNG. Se existir, substitui o ícone vetorial. |

O campo `kind` não altera a lógica; ele só documenta a intenção do item.

### Tags

As tags são ids em inglês definidos em `TAG_NAMES`, que também guarda o texto
em português exibido ao jogador:

```gdscript
const TAG_NAMES := {
	"red": "vermelho",
	"floral": "floral",
	"ocean": "oceano",
	# ...
}
```

Regras importantes:

- uma receita usa **todas** as tags listadas (E lógico, não OU);
- uma tag desconhecida ainda funciona, mas aparece com o próprio id;
- para uma tag nova aparecer bonito na interface, adicione-a a `TAG_NAMES`;
- várias tags no mesmo item permitem que ele sirva a mais de uma receita.

## Adicionando um item

1. Abra `scripts/autoload/item_db.gd`.
2. Adicione uma entrada em `ITEMS` com um id novo em `snake_case`.
3. Escolha um `icon` existente ou aponte `texture` para uma PNG.
4. Use o id no `Item Id` de um `ItemPickup` dentro de uma sala.
5. Se o item for consumido/transformado, crie uma `ItemUseRule` no objeto ou
   trate a combinação no código (veja abaixo).

Exemplo:

```gdscript
"glass_eye": {
	"name": "Olho de Vidro",
	"desc": "Frio ao toque. Parece acompanhar você pela sala.",
	"tags": ["gem", "ocean", "hard"],
	"color": Color("#7fb6c9"),
	"icon": "stone",
	"kind": "clue",
},
```

### Ícones

`item_icon.gd` desenha ícones vetoriais com formas simples. Os nomes atuais são:

```
mushroom, moss, algae, feather, flower, shell, stone, fish, can, meat,
water, potion, syringe_empty, syringe_water, syringe_tranq,
syringe_blood, syringe_monster, knife, rod, music_box, diary, candle
```

Se `icon` não existir, o item cai no desenho padrão (`stone`). Para um ícone
novo, adicione um `case` em `_draw_icon()`.

Se o item tiver `texture`, o desenho vetorial é ignorado e a PNG é ajustada
dentro do slot. Use PNG com fundo transparente, como as de `assets/props/`.

### Texturas de item

Itens que também aparecem no cenário podem compartilhar a mesma PNG. É o caso
de `potion`, `rod`, `bucket`, `sapphire`, `ruby`, `lavender`,
`lavender_revived` e `oyster`:

```gdscript
"ruby": {
	# ...
	"texture": "res://assets/props/rubi.png",
},
```

## Como um item vira conteúdo de sala

O fluxo é sempre o mesmo:

1. `ItemDB` define o item.
2. Um `ItemPickup` na sala aponta para o id.
3. Ao clicar, `GameState.add_item(id)` adiciona ao inventário.
4. A flag `picked_<id>` (ou a `Pickup Flag` configurada) é gravada.
5. O objeto some se `Hide After Pickup` estiver ligado.

O save guarda apenas a lista de ids. Se um id for removido do `ItemDB`, ele é
descartado ao carregar o jogo, sem quebrar o save.

## Transformações e receitas de inventário

Há dois jeitos de transformar itens:

### 1. Usar um item em um objeto (recomendado)

Configure `Use Rules` no `Examine`, `Door` ou `ItemPickup` do cenário:

```
Item Id          = "potion"
Consume Selected = true
Set Flag         = "lavender_revived"
Message          = "A poção escorre entre as folhas secas..."
```

A primeira regra que combinar vence. Use `Once Flag` + `Repeat Message` para
efeitos que só podem acontecer uma vez.

### 2. Combinar dois itens no inventário

Combinações entre dois itens do inventário não passam por `Use Rules`; elas
ficam em `game.gd`, em `_on_item_clicked`. Exemplo atual: chave de fenda na
ostra.

```gdscript
func _on_item_clicked(id: String) -> void:
	if GameState.selected_item == "screwdriver" and id == "oyster":
		_combine_oyster()
		return
	GameState.select_item(id)
```

Ao adicionar uma combinação nova, trate o caso antes do `select_item` e cuide
de remover/adicionar itens, gravar flags e salvar.

## Monstros e o ritual

As criaturas ficam em `MONSTERS`, no mesmo arquivo. Cada entrada tem:

| Campo | Para que serve |
| --- | --- |
| `name` | Nome exibido no cartão de resultado. |
| `title` | Subtítulo curto. |
| `color` | Cor do glifo e do cartão. |
| `recipe` | Lista de tags necessárias (todas). |
| `hints` | Reservado para dicas extras (o leitor da página mostra só a arte). |
| `desc` | Descrição no cartão de resultado. |
| `ability` | Habilidade mostrada no cartão. |
| `victory` | `true` se essa invocação vence a fatia. |

### Como a invocação é resolvida

`ItemDB.resolve_summon()` junta as tags de todos os itens no círculo e testa:

1. a receita de `TARGET` (`carmesim`) primeiro — se bater, ela sempre vence;
2. depois a ordem de prioridade `roxo`, `carmesim`, `azul`, `vermelho`,
   `branco`;
3. se nada bater, retorna `none`.

Como as receitas são por tag, um item com muitas tags pode ativar mais de uma
criatura. A prioridade acima decide o empate.

### Adicionando um monstro

1. Adicione a entrada em `MONSTERS` com um id novo.
2. Defina a `recipe` usando tags já existentes em `TAG_NAMES`.
3. Adicione o id à ordem de prioridade em `resolve_summon()` (se ele puder
   empatar com outros).
4. Se quiser um glifo próprio, adicione um `case` em `monster_glyph.gd`.
5. Lembre que o leitor da página do livro mostra só a arte; os outros monstros
   aparecem no cartão de resultado.

## Checklist de item

1. O id está em `snake_case` e não repete?
2. `name`, `desc` e `tags` estão preenchidos?
3. O `icon` existe em `item_icon.gd`, ou há `texture` válida?
4. O `ItemPickup` da sala usa exatamente esse id?
5. A flag de coleta (`picked_<id>`) está coerente com as condições da sala?
6. Se o item participa de receita, as tags estão em `TAG_NAMES`?
7. Se o item é consumido, a regra/combinação remove o item certo?
8. O save antigo continua carregando (ids removidos são descartados)?

## Onde testar

O teste de fluxo cobre a rota principal e vários itens:

```sh
godot --headless --path . res://tests/flow_test.tscn
```

As capturas de tela incluem os itens do inventário:

```sh
godot --path . res://tests/shots.tscn
```
