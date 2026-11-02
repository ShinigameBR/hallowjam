# CÍRCULO — Um Ritual para Escapar

Protótipo point-and-click de mistério e ocultismo feito para a Hallowjam 2026.

Você acorda preso em uma cabana no meio do mar. Explore os cômodos, resolva
enigmas, encontre oferendas e descubra quais qualidades invocam a criatura que
pode abrir a passagem para o sótão.

## Como jogar

- **Clique** em objetos do cenário para examinar ou pegar.
- **Clique** em um item do inventário para selecioná-lo e depois clique em um
  objeto para usá-lo.
- **Clique com o botão direito** para soltar o item selecionado.
- **LIVRO** abre o grimório com as pistas das invocações.
- **MENU** pausa o jogo.
- **ESC** fecha painéis ou pausa.
- Em builds de debug, **F1** liga/desliga os contornos e etiquetas de
  depuração. No jogo final só o cursor muda ao passar em algo clicável.

## Conteúdo do protótipo

- Menu principal com novo jogo, continuar, como jogar e opções.
- Quatro áreas: sala principal, lado esquerdo, lado direito e cais.
- Livro do bruxo, cofre com senha, círculo de invocação e pistas no cenário.
- Lavanda revivida, rubi, vara de pescar, minhoca, ostra, pérola e peixe.
- Seis monstros possíveis, definidos pelas qualidades dos ingredientes.
- Salvamento automático em `user://circulo_run.cfg`.
- Final jogável desta fatia: invocar **O Beija-Flor Carmesim**, alimentá-lo com
  o peixe e abrir a porta do sótão.

## Executar

Abra a pasta no Godot 4.7 e pressione **F5**, ou:

```sh
godot --path .
```

## Estrutura

- `scenes/rooms/` — uma cena por sala (`main_room.tscn`, `left_room.tscn`,
  `right_room.tscn`, `dock_room.tscn`) e o `room_template.tscn` para criar
  salas novas. As antigas cozinha e porão ficam em `scenes/rooms/legacy/`.
- `scenes/components/` — modelos prontos de `door`, `item_pickup` e `examine`
  para arrastar para dentro das salas.
- `scripts/rooms/` — raiz de sala e o autoload `RoomManager`, que descobre e
  troca as salas automaticamente.
- `scripts/components/` — componentes clicáveis configuráveis pelo inspetor
  (portas, itens, examinar e regras de uso de item).
- `scripts/autoload/` — tema, itens, estado, configurações e transições.
- `scripts/game/` — HUD, painéis, cenário vetorial de exemplo e lógica do ritual.
- `scripts/ui/` — menu, botões e painel de ajuda.
- `tests/` — teste automatizado do fluxo completo e capturas de tela.

Veja a documentação de autoria:

- **[docs/CRIANDO_SALAS.md](docs/CRIANDO_SALAS.md)** — criar salas, camadas,
  arte, hotspots, portas, itens no cenário e ações.
- **[docs/CRIANDO_ITENS.md](docs/CRIANDO_ITENS.md)** — itens, tags, ícones,
  transformações, receitas e monstros.
- **[docs/ESCREVENDO_TEXTOS.md](docs/ESCREVENDO_TEXTOS.md)** — diálogos, falas,
  objetivos, painéis e onde editar cada texto.
- **[docs/FLUXO_E_ESTADO.md](docs/FLUXO_E_ESTADO.md)** — flags, inventário,
  save, reload, objetivos e testes de estado.

O teste de fluxo pode ser executado com:

```sh
godot --headless --path . res://tests/flow_test.tscn
```
