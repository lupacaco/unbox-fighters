# Sistema: arrastar e soltar

Como o jogador move peças até as cartas ou para vender.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/assembly/drag_drop_service.gd` | Serviço central do arraste |
| `scripts/assembly/part_view.gd` | Peça que pode ser arrastada |
| `scripts/assembly/character_slot.gd` | Aceita / rejeita / encaixa a peça |
| `scripts/ui/action_bar.gd` | Botão **VENDER** (também é zona de soltar) |

## Fluxo da peça

1. `PartView` pede para começar o arraste no `DragDropService`
2. Enquanto o mouse se move, a peça segue o cursor
3. O serviço procura uma carta **compatível** sob o cursor. A **carta inteira** acende ouro e cresce um pouco (sem retângulo vermelho).
4. A peça inclinada segue o mouse, fica maior, e a sombra alonga. Em cima da carta ela puxa um pouco mais.
5. Passar por **VENDER** deixa o botão dourado e maior
6. Ao soltar:
   - Na carta que aceita → encaixa
   - Em **VENDER** → some e você recebe metade do que pagou
   - Senão → volta para a prateleira (ou para a carta de onde saiu)

Um clique curto **sem arrastar** seleciona a peça na prateleira. Aí **VENDER** mostra quanto ela vale.

## Regras de aceite (`CharacterSlot.can_accept`)

- A peça não pode ser nula
- Só entram os 2 kits da loja (cabeça e corpo)
- Se o encaixe **já tem** peça, a nova entra e a antiga volta para a prateleira
- Depois que a partida acaba a carta fica travada

## Sinais úteis

- `DragDropService.drag_started` / `drag_ended` / `sell_requested` / `part_clicked`
- `CharacterSlot.part_attached` / `part_detached` / `fight_requested`

## Input

Ação configurada no projeto: `pointer_press` (botão esquerdo do mouse).  
O término do arraste também observa soltar o botão esquerdo.
