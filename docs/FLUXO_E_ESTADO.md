# Fluxo, flags e save

O estado da partida inteira fica em `GameState`
(`scripts/autoload/game_state.gd`). Salas e componentes não guardam estado
próprio: eles leem e escrevem flags nesse autoload. Assim o save, o reload e a
troca de sala continuam consistentes.

> Para criar salas, veja [CRIANDO_SALAS.md](CRIANDO_SALAS.md). Para itens, veja
> [CRIANDO_ITENS.md](CRIANDO_ITENS.md). Para textos, veja
> [ESCREVENDO_TEXTOS.md](ESCREVENDO_TEXTOS.md).

## O que o GameState guarda

| Dado | Tipo | Para que serve |
| --- | --- | --- |
| `inventory` | `Array[String]` | Itens na mochila, em ordem de aquisição. |
| `circle` | `Array[String]` | Quatro espaços do círculo (`""` = vazio). |
| `flags` | `Dictionary` | Estado do mundo (quase sempre `bool`). |
| `current_room` | `String` | `room_id` da sala atual. |
| `objective` | `String` | Texto do objetivo no HUD. |
| `play_time` | `float` | Tempo de jogo, mostrado na vitória. |
| `monsters_seen` | `Array[String]` | Criaturas já invocadas. |
| `selected_item` | `String` | Item selecionado no inventário. |
| `run_started` | `bool` | Impede salvar uma partida que ainda não começou. |

O `GameState` não guarda a posição do jogador nem o nó da sala: a sala atual é
recarregada a partir de `current_room`.

## Sinais

Quem precisa reagir a mudanças conecta nos sinais em vez de consultar o estado
a cada frame:

| Sinal | Emitido quando |
| --- | --- |
| `inventory_changed` | Um item entra ou sai do inventário. |
| `circle_changed` | O círculo muda. |
| `selection_changed` | O item selecionado muda. |
| `flags_changed` | Uma flag é criada, alterada ou removida. |
| `objective_changed(text)` | O objetivo muda. |
| `toast(text)` | Um aviso rápido deve aparecer. |
| `dialogue_requested(lines)` | Uma fala deve abrir. |
| `panel_requested(panel_id)` | Um painel deve abrir. |
| `action_requested(action_id, source)` | Uma ação especial deve rodar. |

Os componentes já se conectam a `flags_changed` para mostrar/esconder objetos e
atualizar o hover. A HUD se conecta a `objective_changed`; o `game.gd` conecta
os sinais de diálogo, painel e ação.

## Flags

### Como escrever

```gdscript
GameState.set_flag("minha_flag")            # true
GameState.set_flag("contador", 3)           # valor qualquer
GameState.has_flag("minha_flag")            # bool
GameState.clear_flag("minha_flag")          # remove
```

Use `set_flag`/`clear_flag` sempre que possível; eles emitem
`flags_changed`, e os hotspots se atualizam sozinhos.

### Convenções de nome

| Padrão | Exemplo | Significado |
| --- | --- | --- |
| `picked_<item>` | `picked_key` | O item do mundo foi coletado. |
| `<objeto>_seen` | `door_clue_seen` | O jogador viu uma pista. |
| `<objeto>_open` | `safe_open` | Algo foi aberto/destrancado. |
| `<objeto>_done` | `intro_done` | Um evento de uma vez já aconteceu. |
| `<objeto>_<estado>` | `lavender_revived` | Transformação de objeto. |

### Flags atuais da fatia

| Flag | Significado |
| --- | --- |
| `intro_done` | A introdução já foi mostrada. |
| `picked_<item>` | O item do mundo já foi coletado. |
| `book_read` | A página do livro foi aberta no ícone do topo do HUD. |
| `shelf_seen` | O zoom do canto da estante foi aberto. |
| `sun_clock_seen` | O relógio do sol foi examinado. |
| `door_clue_seen` | A pista na porta da frente foi encontrada. |
| `front_door_open` | A porta da frente foi destrancada com a chave. |
| `lavender_revived` | A poção reviveu a lavanda. |
| `fire_out` | A lareira foi apagada com o balde de água. |
| `safe_open` | O cofre foi aberto com o código 3142. |
| `ruby_taken` | O rubi saiu do cofre. |
| `summoned_carmesim` | O Beija-Flor Carmesim foi invocado. |
| `dirt_dug` | O buraco na areia do cais foi cavado. |
| `picked_bait` / `picked_suitcase` | A minhoca / a maleta foram pegas no buraco. |
| `fish_caught` | O peixe foi pescado. |
| `carmesim_fed` | O Carmesim comeu e abriu a porta do sótão. |
| `won` | O jogo foi concluído. |

`monsters_seen` não é uma flag: é uma lista separada, usada pelo menu de pausa
e pela tela de vitória.

## Inventário e seleção

- `add_item(id)` valida o id no `ItemDB` e avisa se ele não existir.
- O inventário aceita duplicatas; `item_count(id)` conta quantas existem.
- `remove_item(id)` remove a primeira ocorrência.
- `select_item(id)` alterna a seleção; clicar de novo no mesmo item desmarca.
- `clear_selection()` é chamada ao usar um item, trocar de sala ou clicar com o
  botão direito.
- `replace_item(old, new)` remove um e adiciona outro.
- `book_page` não aparece na barra inferior: o item é obtido ao clicar na
  estante, ganha um ícone próprio no canto superior do HUD e abre o leitor de
  página.

## Círculo

- `place_in_circle(slot, id)` move um item do inventário para o círculo.
- `take_from_circle(slot)` devolve o item para o inventário.
- `clear_circle()` devolve todas as oferendas.
- `consume_circle()` esvazia o círculo **sem** devolver (usado na invocação
  bem-sucedida).

O `ItemDB.resolve_summon()` lê as tags dos itens no círculo e devolve o id da
criatura. Quem consome ou devolve as oferendas é o `game.gd`, não o painel.

## Save

O save fica em:

```
user://circulo_run.cfg
```

Ele é gravado automaticamente em momentos importantes (coleta, uso de item,
troca de sala, invocação, coleta de pistas, etc.) e sempre que o menu é aberto.
O save da partida é separado das preferências (`user://settings.cfg`).

Campos salvos: inventário, círculo, flags, sala atual, objetivo, tempo de jogo
e criaturas vistas. A seleção de item não é salva.

Ao carregar:

- ids de itens que não existem mais no `ItemDB` são descartados;
- ids de monstros desconhecidos também são descartados;
- se a sala salva não existir mais, o jogo volta para `main`;
- a seleção começa vazia.

Ao vencer, `GameState.delete_save()` apaga o save para que "Continuar" não
reabra uma partida concluída. "Jogar novamente" chama `start_new_game()`.

### Adicionando um dado persistente

Se você criar um novo campo de estado que precisa sobreviver ao reload:

1. adicione a variável no topo de `game_state.gd`;
2. inicialize em `start_new_game()`;
3. inclua em `_emit_all()` se a interface precisar reagir;
4. salve em `save_game()`;
5. carregue em `load_game()` com um valor padrão seguro.

## Reinício e menu

- `start_new_game()` limpa inventário, círculo, flags, sala, objetivo, tempo,
  criaturas vistas e seleção.
- O menu principal chama `SceneTransition.change_scene()`; o jogo não recarrega
  o autoload.
- `main` é sempre a sala inicial.
- `GameState.ROOMS` lista os ids esperados da fatia, mas a descoberta real é
  feita pelo `RoomManager` varrendo `scenes/rooms/`.

## Testes

Teste de fluxo completo:

```sh
godot --headless --path . res://tests/flow_test.tscn
```

O teste usa os mesmos pontos de entrada do jogo (`_on_hotspot`,
`_on_item_clicked`, `_on_summon_requested`) e verifica flags, inventário e
estado final. Se você adicionar uma etapa obrigatória, atualize
`tests/flow_test.gd` junto.

Capturas de tela:

```sh
godot --path . res://tests/shots.tscn
```

## Checklist de estado

1. A flag tem nome claro e segue a convenção?
2. `set_flag`/`clear_flag` são usados em vez de mexer no dicionário direto?
3. O componente esconde/mostra o objeto com `Hide/Show When Flags`?
4. O save é gravado depois da mudança?
5. O objetivo é atualizado em `_refresh_objective()`?
6. O reload restaura o estado esperado?
7. O teste de fluxo continua passando?
