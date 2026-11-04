# Escrevendo textos e diálogos

Quase todo texto do jogo fica em dois lugares:

- **no inspetor**, nos campos dos componentes da sala;
- **em scripts**, para falas globais, painéis e textos de interface.

Não há sistema de tradução/localização. Os textos são escritos diretamente em
português nos `.tscn` e `.gd`.

## Onde cada texto aparece

| Texto | Onde editar | Quando aparece |
| --- | --- | --- |
| Nome do objeto no hover | `Label` do componente | Hover de depuração (debug + F1). |
| Fala de um objeto | `Examine > Message` / `Speaker` | Clique no objeto. |
| Texto de bloqueio | `Examine > Blocked Message` | `Required Flag` ainda falsa. |
| Texto de item errado | `Examine > Wrong Item Message` | Clique com item selecionado. |
| Texto de repetição | `Examine > Repeat Message` | Depois de `Once Flag`. |
| Descrição de coleta | `ItemPickup > Description` | Ao pegar o item. |
| Mensagens de coleta | `Blocked / Wrong Item / Already Message` | Condições de coleta. |
| Fala de uso de item | `ItemUseRule > Message` / `Speaker` | Regra de uso aplicada. |
| Repetição de uso | `ItemUseRule > Repeat Message` | Regra com `Once Flag` já usada. |
| Porta trancada | `Door > Locked Message` | Tentativa de abrir sem condição. |
| Porta destrancada | `Door > Unlock Message` | Aviso opcional ao abrir. |
| Introdução | `game.gd > _maybe_intro()` | Primeiro acesso à partida. |
| Final da fatia | `game.gd > _finish_game()` | Porta do sótão após alimentar o Carmesim. |
| Objetivo do HUD | `game.gd > _refresh_objective()` | Sempre que uma flag muda. |
| Falas de ação | `game.gd > _action_*` | Ações `safe`, `sea`, `dig`, `attic`. |
| Página do livro | `scripts/game/book_panel.gd` | Hotspot da estante ou ícone no topo do HUD. |
| Diário | `scripts/game/diary_panel.gd` | Item `diary` / hotspot do diário. |
| Estante | `scripts/game/shelf_zoom.gd` | Hotspot do canto da estante. |
| Círculo | `scripts/game/circle_panel.gd` | Hotspot do círculo. |
| Cartão de invocação | `scripts/game/monster_result_panel.gd` | Fim de uma invocação. |
| Nomes/descrições de monstros | `ItemDB.MONSTERS` | Cartão de resultado. |
| Como jogar | `scripts/ui/help_panel.gd` | Menu e pausa. |
| Tela de vitória | `scripts/game/win_panel.gd` | Fim do protótipo. |
| Menu principal | `scripts/ui/main_menu.gd` | Tela inicial. |

## Diálogo

O diálogo é um cartão na parte de baixo da tela, com efeito de máquina de
escrever. O jogador avança clicando, apertando **ESC** ou usando o botão
**CONTINUAR**.

### Uma fala simples

Dentro de um componente, use `say()`:

```gdscript
say("A gaveta está emperrada.")
say("O mar não devolve o que toma.", "VOZ DISTANTE")
```

Na prática, os campos do inspetor (`Message`, `Speaker`) chamam esse mesmo
caminho. Você só precisa escrever `say()` quando a fala depender de lógica.

### Várias falas em sequência

Use `show_dialog()` com uma lista de dicionários:

```gdscript
_show_dialog([
	{"speaker": "O CARMESIM", "text": "Ele bate as asas e espera."},
	{"text": "Você sente o cheiro de maresia e poeira."},
	{"text": "A passagem range, mas cede."},
])
```

Cada linha aceita:

| Chave | Obrigatória? | Efeito |
| --- | --- | --- |
| `text` | sim | Corpo da fala. |
| `speaker` | não | Nome em destaque acima do texto. |

Também é aceito um array de strings; nesse caso cada string é uma fala sem
locutor:

```gdscript
GameState.show_dialog(["Primeira fala.", "Segunda fala."])
```

### Avisos rápidos (toast)

Para mensagens curtas que não devem pausar o jogo, use:

```gdscript
GameState.notify("Selecione um ingrediente no inventário.")
```

Toasts aparecem no topo/centro e desaparecem sozinhos. Use para feedback
imediato; reserve o diálogo para narrativa e consequências.

## Objetivos

O texto do objetivo é recalculado em `_refresh_objective()`, em `game.gd`, a
partir das flags. Para mudar a ordem ou o texto da rota:

1. localize o `elif` correspondente à flag;
2. ajuste a string;
3. mantenha a lógica em ordem de prioridade (o primeiro caso verdadeiro vence).

Exemplo:

```gdscript
elif not GameState.has_flag("lavender_revived"):
	text = "A lavanda murcha pede a poção."
```

O objetivo inicial (`Uma página solta repousa sobre a estante.`) também está em
`GameState.start_new_game()` e em `GameState.objective`.

## Textos de painéis

### Página do livro

`book_panel.gd` é só um visualizador de imagem: ele exibe
`assets/props/pagina_do_livro_aberta.jpeg` em tela cheia, sem textos, botões ou
outros elementos de HUD. Fecha com clique, botão direito ou **Esc**.

A página em si é o item `book_page`, pego como um objeto sobre a estante. O ícone
dela aparece no canto superior do HUD; a barra inferior não mostra esse item. O
canto da estante tem um hotspot separado que abre o zoom da tábua e da chave.

### Diário

As páginas do diário são chamadas de `_page_line(page, "...")` em
`diary_panel.gd`. Cada chamada é um parágrafo. O texto usa uma cor escura sobre
o papel claro, então evite markup: os labels são `Label`, não `RichTextLabel`.

### Teclado

Além do código (`CODE = "3142"`), o painel mostra a ordem das cores e mensagens
como `"Faltam números."`, `"O cofre cede..."` e `"O cofre não cede."`.

### Cartão de invocação

Nome, título, descrição e habilidade vêm de `ItemDB.MONSTERS`. O botão muda
entre `PARTIR` (vitória) e `RECOLHER OFERENDAS` (fracasso).

## Limites e estilo

- O diálogo ocupa ~84% da largura e cerca de 2 a 4 linhas. Prefira falas de
  1 a 3 frases.
- Objetivos aparecem como texto simples sob o nome da sala e quebram linha
  automaticamente; use no máximo duas frases curtas e evite instruções óbvias.
- Painéis têm larguras fixas (por exemplo, diário 824 px, círculo 780 px,
  cofre 470 px). Textos longos devem usar `autowrap_mode`, como já acontece
  nos painéis.
- Os labels não interpretam BBCode/HTML. Para destaque, use os estilos da UI
  (`Eyebrow`, `H1`, `H2`, `Muted`, `Tiny`, etc.) ou cores definidas em
  `scripts/autoload/ui.gd`.
- Mantenha o tom do protótipo: presente, direto, sensorial, sem nomear o
  protagonista.
- Nomes de locutor são exibidos em maiúsculas no cartão, mas escreva-os como
  quiser no campo `Speaker`.

## Boas práticas

1. **Um fato por fala.** Evite parágrafos enormes no diálogo.
2. **Não repita o objetivo no texto**; o HUD já mostra o próximo passo.
3. **Use flags para decidir o texto**, não para esconder informação essencial.
4. **Escreva a consequência antes da instrução**: "A porta cede. Suba." em vez
   de "Use a porta para subir".
5. **Teste com o fluxo completo** para pegar falas fora de ordem ou objetivos
   que não atualizam.

## Testando textos

O teste de fluxo percorre a rota principal e fecha os diálogos automaticamente:

```sh
godot --headless --path . res://tests/flow_test.tscn
```

Para revisar visualmente os painéis e a quebra de linha:

```sh
godot --path . res://tests/shots.tscn
```

As imagens são salvas em `tests/shots/`.
