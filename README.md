# CÍRCULO — Um Ritual para Escapar

Protótipo point-and-click de mistério e ocultismo feito para a Hallowjam 2026.

Você acorda preso em uma cabana no meio do mar. Explore os cômodos, resolva
enigmas, encontre oferendas e descubra quais qualidades invocam o monstro que
pode te levar de volta.

## Como jogar

- **Clique** em objetos do cenário para examinar ou pegar.
- **Clique** em um item do inventário para selecioná-lo e depois clique em um
  objeto para usá-lo.
- **Clique com o botão direito** para soltar o item selecionado.
- **LIVRO** abre o grimório com as pistas das invocações.
- **MENU** pausa o jogo.
- **ESC** fecha painéis ou pausa.

## Conteúdo do protótipo

- Menu principal com novo jogo, continuar, como jogar e opções.
- Quatro áreas: sala principal, cozinha, porão e cais.
- Cofre com senha, diário, criatura na jaula e ritual de invocação.
- Seis monstros possíveis, definidos pelas qualidades dos ingredientes.
- Salvamento automático em `user://circulo_run.cfg`.
- Final jogável da primeira fase: invocar **O Errante Verde**.

## Executar

Abra a pasta no Godot 4.7 e pressione **F5**, ou:

```sh
godot --path .
```

## Estrutura

- `scenes/` — cenas de menu e jogo.
- `scripts/autoload/` — tema, itens, estado, configurações e transições.
- `scripts/game/` — salas, HUD, painéis e lógica do ritual.
- `scripts/ui/` — menu, botões e painel de ajuda.
- `tests/` — teste automatizado do fluxo completo e capturas de tela.

O teste de fluxo pode ser executado com:

```sh
godot --headless --path . res://tests/flow_test.tscn
```
