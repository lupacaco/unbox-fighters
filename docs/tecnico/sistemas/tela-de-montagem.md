# Sistema: tela de montagem

A cena principal do jogo hoje.

## Arquivos

| Tipo | Caminho |
|------|---------|
| Cena | `scenes/assembly/Assembly.tscn` |
| Controlador | `scripts/assembly/assembly_controller.gd` (`AssemblyController`) |
| Cenas filhas | `CharacterSlot.tscn`, `Crate.tscn`, `PartView.tscn` |

## O que o controlador faz ao iniciar

1. Registra o `DragDropService` no grupo `drag_drop_service`
2. Carrega o elenco (vampiro, policial, bruxa) só para nomear sets completos
3. Monta a lista de recompensas das 9 caixas (set completo de cada um)
4. Ajusta a prateleira visual
5. Liga as **3 cartas e 9 caixas que já estão na cena** (não cria cópias novas)
6. Liga o serviço de arraste às cartas e à bandeja
7. Toca a intro (fade do título)

No editor 2D você já vê fundo, cartas, prateleira e caixas. O Play só “liga” o jogo (abrir caixa, arrastar, LUTAR).

## Layout aproximado

- Cartas em X ≈ 380, 960, 1540; Y ≈ 400
- Prateleira / bandeja em torno de Y ≈ 920
- Caixas: altura visual ≈ 185 px; posição de descanso Y ≈ -58 (relativo à bandeja)
- Shelf (prateleira): Y ≈ 58 relativo à bandeja
- Sombra da caixa: oval baixa só embaixo (luz de cima)
- Título e subtítulo no HUD

## Recompensas atuais das caixas

Ordem fixa (dados de teste):

1–3. Set completo do vampiro  
4–6. Set completo do policial  
7–9. Set completo da bruxa

## Botão LUTAR

Cada carta tem um botão **LUTAR** acima dela (só se o personagem tiver poses de perfil/ataque).  
Detalhes: [Animação de luta](animacao-de-luta.md).

## Abrir caixa (`Crate`)


Sprites em `assets/boxes/`:

| Arquivo | Estado |
|---------|--------|
| `box-01.png` | Intacta |
| `box-02.png` | Trincada (após 1º clique) |
| `box-03.png` | Quebrada (após 2º clique; some após 0,5 s) |

Fluxo: 2 cliques → some → instancia `PartView` com a peça da caixa.  
Cursor: hover usa `hammer-01`; cada batida usa `hammer-02` por 0,2 s.

## Relação com outras cenas

- `Crate` — 2 cliques → some → instancia `PartView`  
- `CharacterSlot` — recebe peças via `DragDropService`
