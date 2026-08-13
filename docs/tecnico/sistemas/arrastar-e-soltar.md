# Sistema: arrastar e soltar

Como o jogador move peças (e Freaks inteiros) até as cartas ou para vender.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/assembly/drag_drop_service.gd` | Serviço central do arraste |
| `scripts/assembly/part_view.gd` | Peça que pode ser arrastada |
| `scripts/assembly/character_slot.gd` | Aceita / rejeita / encaixa a peça; arraste pelo rótulo da fila |

## Fluxo da peça

1. `PartView` pede para começar o arraste no `DragDropService`
2. Enquanto o mouse se move, a peça segue o cursor
3. O serviço procura uma carta **compatível** sob o cursor e acende o destaque
4. Ao soltar:
   - Na carta que aceita → encaixa
   - Em **VENDER** → some e você ganha 1 pancada
   - Senão → volta para a prateleira

## Fluxo do Freak inteiro

Arrastar pelo rótulo **3º / 2º / 1º**:

- Soltar em outra carta → troca a ordem da fila
- Soltar em **VENDER** → vende o Freak por 1 pancada

## Regras de aceite (`CharacterSlot.can_accept`)

- A peça não pode ser nula
- Qualquer peça do tipo certo serve em qualquer carta
- Se o encaixe **já tem** peça, a nova entra e a antiga volta para a prateleira
- Durante a luta a carta fica travada

## Sinais úteis

- `DragDropService.drag_started` / `drag_ended` / `part_sold` / `card_sold` / `cards_swapped`
- `CharacterSlot.part_attached` / `part_detached` / `card_drag_requested`

## Input

Ação configurada no projeto: `pointer_press` (botão esquerdo do mouse).  
O término do arraste também observa soltar o botão esquerdo.  
O **botão direito** vende a peça embaixo do cursor (na prateleira ou na carta).
