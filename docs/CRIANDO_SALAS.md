# Criando salas e interações

O jogo é montado com **cenas de sala separadas**. Cada sala tem o seu próprio
`.tscn`, a sua arte e os seus objetos clicáveis. A lógica do jogo não sabe onde
ficam as portas nem os itens: ela carrega a cena da sala e os componentes avisam
quando algo acontece.

> Este guia cobre salas e hotspots. Para itens, veja
> [CRIANDO_ITENS.md](CRIANDO_ITENS.md). Para diálogos e textos, veja
> [ESCREVENDO_TEXTOS.md](ESCREVENDO_TEXTOS.md). Para flags, save e objetivos,
> veja [FLUXO_E_ESTADO.md](FLUXO_E_ESTADO.md).

## Visão geral

```
scenes/
  rooms/
    room_template.tscn     ← comece duplicando esta
    main_room.tscn         ← sala principal
    left_room.tscn         ← lado esquerdo
    right_room.tscn        ← lado direito
    dock_room.tscn         ← cais
    legacy/                ← cozinha e porão antigos, fora da rotação atual
  components/
    door.tscn
    item_pickup.tscn
    examine.tscn
scripts/
  rooms/
    room.gd                ← raiz de toda sala
    room_manager.gd        ← autoload que troca as salas
  components/
    interactable.gd        ← base de todos os clicáveis
    door.gd
    item_pickup.gd
    examine.gd
    item_use_rule.gd
```

As salas são descobertas automaticamente pelo `room_id`. Não existe uma lista
fixa de salas no código.

**Importante:** o `RoomManager` varre apenas os arquivos `.tscn` que estão
diretamente em `scenes/rooms/`. Salas dentro de subpastas (como `legacy/`) não
entram na rotação automática.

## Antes de começar: tamanho e camadas

O projeto roda em **1280×720** com `window/stretch/mode = canvas_items` e
`aspect = expand`. As artes de fundo atuais têm **1600×785** ou **2200×1080** e
são exibidas com:

- `expand_mode = Ignore Size` (`1`);
- `stretch_mode = Keep Aspect Covered` (`6`);
- `mouse_filter = Ignore` (`2`).

Isso preenche a tela sem distorcer a imagem, cortando um pouco as laterais.
Use esse mesmo formato ao criar uma sala nova para manter a composição.

### Arte atual

| Arquivo | Uso |
| --- | --- |
| `assets/backgrounds/sala_principal.png` | Sala principal. |
| `assets/backgrounds/sala_esquerda.jpeg` | Lado esquerdo. |
| `assets/backgrounds/sala_direita.jpeg` | Lado direito. |
| `assets/backgrounds/cais_buraco_fechado.png` / `cais_buraco_cavado.png` | Cais (antes e depois de cavar). |
| `assets/backgrounds/zoom_buraco_fechado.png` / `zoom_buraco_cavado.png` | Zoom do buraco na areia do cais. |
| `assets/backgrounds/menu_principal.png` | Fundo do menu principal. |
| `assets/backgrounds/fim_do_jogo.png` | Ilustração da tela de vitória. |
| `assets/props/*.png` | Recortes transparentes de objetos e itens. |
| `assets/backgrounds/zoom_canto_estante_fechado.png` | Zoom do canto da estante com a tábua fechada. |
| `assets/backgrounds/zoom_canto_estante_aberto.png` | Zoom do canto da estante com a tábua aberta. |
| `assets/backgrounds/dica_da_porta.png` | Dica na porta da frente (`HintDoor`). |
| `assets/props/chave.png` | Chave escondida atrás da tábua da estante. |
| `assets/props/pagina_do_livro.png` | Página pegável na estante e ícone transparente no topo do HUD. |
| `assets/props/pagina_do_livro_aberta.jpeg` | Página aberta exibida sozinha ao abrir o ícone. |

Os arquivos originais de referência ficam em `artifacts/`. Ao integrar uma arte
nova, mova a versão usada para `assets/` e apague a cópia que ficou em
`artifacts/assets/`.

Cada sala dos exemplos tem esta ordem de nós:

```
Room (Control, room.gd)
├── Background (TextureRect)      ← arte de fundo, não recebe cliques
├── Interactables (Control)       ← camada dos objetos clicáveis
│   ├── Door
│   ├── ItemPickup
│   └── Examine
└── Spawn_default (Control)       ← marcador de entrada
```

A raiz e as camadas devem ficar com `mouse_filter = Ignore`; os componentes
clicáveis usam `mouse_filter = Stop` automaticamente.

## Criando uma sala nova

1. Duplique `scenes/rooms/room_template.tscn`.
2. Renomeie o arquivo, por exemplo `scenes/rooms/attic_room.tscn`.
3. Selecione o nó raiz e preencha no inspetor:
   - **Room Id**: `attic` (único; usado pelo save e por portas por id).
   - **Display Name**: `SÓTÃO` (aparece no HUD).
4. Coloque a arte dentro de `Background` (ou de outro nó de imagem):
   - prefira um `TextureRect` em tela cheia com as configurações acima;
   - mantenha `mouse_filter = Ignore` em toda a arte que não for clicável.
5. Apague ou esconda o nó `Backdrop` quando a sua arte estiver pronta. Ele é só
   o cenário vetorial de exemplo.
6. Adicione os objetos clicáveis dentro de `Interactables`.
7. Crie pelo menos um marcador de entrada (veja abaixo).
8. Salve. A sala já pode ser aberta por uma `Door` que aponte para o `.tscn` ou
   para o `room_id`.

### Posicionamento

Os clicáveis usam âncoras normalizadas (`0.0` a `1.0`) para acompanhar o
tamanho da janela. Você pode:

- usar âncoras + `offsets` para acompanhar o fundo;
- usar posições absolutas se a sala tiver tamanho fixo;
- arrastar o nó no editor e ajustar a área até cobrir a imagem que o jogador
  deve clicar.

Dica prática: dê prioridade à área clicável, não ao desenho. Um `Control`
invisível sobre a região certa funciona tão bem quanto um `TextureRect` com a
arte do objeto.

### Marcadores de entrada (`Spawn`)

Uma porta pode escolher onde o jogador aparece na sala de destino:

- o marcador é um `Control` chamado `Spawn_<nome>`;
- `Spawn_point = "default"` procura `Spawn_default`;
- se o nome não existir, o jogo usa `Spawn_default`;
- sem nenhum dos dois, a porta ainda troca de sala, mas não reposiciona nada.

Exemplo: a porta do cais usa `Spawn_default`; a porta lateral pode usar
`Spawn_main_left` para o jogador aparecer ao lado da porta certa.

## Componentes clicáveis

Todos herdam de `Interactable` e podem ser anexados diretamente a um `Control`
ou `TextureRect`. Campos comuns:

| Campo | Para que serve |
| --- | --- |
| `Interaction Id` | Id estável do objeto. Use o mesmo id em testes e código customizado. |
| `Label` | Texto mostrado no hover de depuração. |
| `Enabled` | Desliga o clique sem esconder o objeto. |
| `Hide When Flags` | Esconde o objeto quando **qualquer** flag da lista for verdadeira. |
| `Show When Flags` | Só mostra o objeto quando **todas** as flags forem verdadeiras. |
| `Use Rules` | Reações a itens do inventário (veja abaixo). |
| `Cursor Shape` | Cursor usado no hover. O padrão é a mãozinha. |

### Hover de depuração

O contorno e a etiqueta de hover são **ferramentas de desenvolvimento**:

- em build de debug, começam ligados;
- **F1** liga/desliga durante o playtest;
- em build de release ficam desligados e o jogo apenas troca o cursor.

`Always Show Label`, `Label Below`, `Label Offset` e `Outline Enabled` só têm
efeito quando o hover de depuração está ligado.

## Door

Anexe `scripts/components/door.gd` a uma imagem de porta e configure:

| Campo | Efeito |
| --- | --- |
| `Target Scene` | `.tscn` da sala de destino (recomendado). |
| `Target Room Id` | Alternativa: o `room_id` de outra sala. |
| `Use Previous Room` | Volta para a sala anterior no histórico. |
| `Spawn Point` | Nome do marcador `Spawn_<nome>` na sala de destino. |
| `Locked` | Mantém a porta fechada. |
| `Required Item` | Item que precisa estar **selecionado** para abrir. |
| `Consume Key` | Remove o item usado ao destrancar. |
| `Required Flag` | Flag necessária para abrir. |
| `Clue Flag` | Flag gravada na primeira vez que o jogador encontra a porta trancada. |
| `Unlock Flag` | Flag gravada ao destrancar; mantém a porta aberta após reload. |
| `Locked Message` | Texto ao tentar abrir trancada. |
| `Unlock Message` | Aviso opcional ao destrancar. |

Se `Unlock Flag` já estiver verdadeira, a porta abre sem pedir nada. Uma porta
com `Locked = true` mas sem item/flag é uma porta permanentemente selada.

## Item Pickup

Anexe `scripts/components/item_pickup.gd` a uma imagem de item:

| Campo | Efeito |
| --- | --- |
| `Item Id` | Id existente em `ItemDB` (`potion`, `ruby`, `bucket`, ...). |
| `Pickup Flag` | Flag gravada ao pegar. Vazio vira `picked_<item_id>`. |
| `Description` | Texto exibido ao pegar. |
| `Hide After Pickup` | Esconde o objeto depois de coletado. |
| `Required Flag` | Só permite pegar depois de uma condição. |
| `Blocked Message` | Texto quando `Required Flag` ainda não foi cumprida. |
| `Wrong Item Message` | Texto ao clicar com outro item selecionado. |
| `Already Message` | Texto ao clicar de novo depois de pegar. |

O objeto some sozinho quando a flag de coleta fica verdadeira, então o save e o
reload continuam corretos.

## Examine

Anexe `scripts/components/examine.gd` a qualquer objeto que não seja porta nem
item. Ele serve para:

| Campo | Efeito |
| --- | --- |
| `Message` | Fala exibida ao clicar. |
| `Speaker` | Nome exibido acima da fala (opcional). |
| `Wrong Item Message` | Texto ao clicar com um item selecionado. |
| `Ignore Selected Item` | Ignora o item selecionado e sempre executa a ação. |
| `Action Id` | Ação especial tratada em `game.gd`. |
| `Open Panel` | Abre `book`, `shelf`, `circle`, `safe`, `drawers` ou `diary`. |
| `Set Flag` | Flag gravada após um clique normal. |
| `Give Item` | Item adicionado após um clique normal. |
| `Once Flag` | Efeitos só acontecem uma vez; depois mostra `Repeat Message`. |
| `Required Flag` | Só funciona depois que a flag for verdadeira. |
| `Blocked Message` | Texto quando `Required Flag` ainda não foi cumprida. |

Os efeitos são aplicados nesta ordem: `Action Id`, `Open Panel`, `Set Flag`,
`Give Item`, `Message`, `Once Flag`.

## Usando um item em um objeto

Cada componente tem o array **Use Rules**. Cada regra é um `ItemUseRule`:

| Campo | Efeito |
| --- | --- |
| `Item Id` | Item necessário. |
| `Needs Selection` | `true`: o item precisa estar selecionado. `false`: basta ter no inventário. |
| `Required Flags` | Todas precisam ser verdadeiras. |
| `Forbidden Flags` | Nenhuma pode ser verdadeira. |
| `Consume Selected` | Remove o item selecionado. |
| `Consume Item` | Remove outro item específico (ex.: isca). |
| `Give Item` | Adiciona outro item. |
| `Set Flag` / `Clear Flag` | Alteram o mundo. |
| `Consume Source` | Esconde o objeto dono da regra. |
| `Once Flag` | A regra só paga uma vez; depois mostra `Repeat Message`. |
| `Message` / `Speaker` | Fala exibida. |
| `Open Panel` / `Action Id` | Painel ou ação especial. |

As regras são avaliadas na ordem. A primeira que combinar vence. Isso permite
coisas como:

- poção na lavanda murcha → a flor revive e pode ser colhida;
- balde com água na lareira → apaga o fogo e revela a safira;
- balde vazio no mar → enche o balde de água;
- peixe no Beija-Flor Carmesim → ele abre a porta do sótão.

Se uma regra tiver `Item Id` vazio e `Needs Selection = false`, ela combina com
qualquer clique e funciona como reação padrão. Use isso com cuidado: ela pode
esconder o comportamento normal do objeto.

## Painéis e ações especiais

Painéis são identificados por string:

| Id | Painel |
| --- | --- |
| `book` | Página do livro: aberta pelo ícone do topo do HUD; só a arte aberta, sem textos nem botões. |
| `shelf` | Zoom do canto da estante com a tábua e a chave. |
| `circle` | Círculo de invocação. |
| `safe` | Baú/cofre de números. |
| `drawers` | Zoom das gavetas. |
| `door_hint` | Dica na porta da frente: só a imagem. |
| `hole` | Zoom do buraco na areia do cais: cava e mostra maleta + minhoca. |
| `rod` | Zoom da vara de pescar do cais: ostra no anzol, isca, linha esticada e peixe. |
| `diary` | Diário do bruxo. |

Eles são abertos por `Open Panel` no `Examine` ou em uma `ItemUseRule`. Para
criar um painel novo, adicione o nó em `game.gd`, registre o id em
`_on_panel_requested` e crie o script correspondente.

Ações que não cabem em uma regra usam `Action Id` e são tratadas em
`_on_action`, em `scripts/game/game.gd`. As ações atuais são:

| Id | Efeito |
| --- | --- |
| `safe` | Abre o teclado ou informa que o cofre já está aberto. |
| `sea` | Lembra que a pescaria é feita na vara do cais. |
| `attic` | Termina o protótipo se o Carmesim já foi alimentado. |

Para adicionar uma ação:

```gdscript
func _on_action(action_id: String, source: Node = null) -> void:
	match action_id:
		"minha_acao":
			_minha_acao(source)
		_:
			push_warning("Unknown action id '%s'." % action_id)
```

O `source` é o nó que disparou a ação, caso você precise consultar posição ou
outros dados do objeto.

## Descoberta de salas e save

- O `RoomManager` registra toda cena de `scenes/rooms/` cujo nó raiz use
  `room.gd` e tenha `room_id` não vazio.
- `GameState.current_room` guarda o id da sala atual no save.
- Ao carregar um save, se a sala não existir mais, o jogo volta para `main`.
- Adicionar ou renomear uma sala não exige alterar listas fixas.
- Se você renomear um `room_id`, saves antigos que apontavam para o id anterior
  caem na sala `main`.

## Checklist de uma sala nova

1. O `.tscn` está diretamente em `scenes/rooms/`?
2. O nó raiz usa `room.gd` e tem `Room Id` + `Display Name`?
3. O fundo cobre a tela sem distorcer e tem `mouse_filter = Ignore`?
4. Existe um `Spawn_default` (e marcadores extras, se necessário)?
5. Cada hotspot tem `Interaction Id` e `Label`?
6. Portas apontam para um `.tscn` ou `room_id` válido?
7. Itens usam ids que existem em `ItemDB`?
8. Flags de coleta/estado estão coerentes com o save?
9. O hover de depuração foi testado com **F1**?

## Teste rápido

Depois de criar ou editar uma sala, rode o teste de fluxo:

```sh
godot --headless --path . res://tests/flow_test.tscn
```

O teste usa os `Interaction Id` atuais (`book_page`, `bookshelf_corner`,
`main_door`, `lavender_wilted`, `sea`, `dirt`, `carmesim`, `attic_door`, ...). Se
você renomear esses ids nas salas de exemplo, atualize também
`tests/flow_test.gd`.

Para gerar capturas de tela das salas e painéis:

```sh
godot --path . res://tests/shots.tscn
```
