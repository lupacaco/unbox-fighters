# Sistema: arrastar e soltar

Como o jogador move peças até as cartas.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/assembly/drag_drop_service.gd` | Serviço central do arraste |
| `scripts/assembly/part_view.gd` | Peça que pode ser arrastada |
| `scripts/assembly/character_slot.gd` | Aceita / rejeita / encaixa a peça |

## Fluxo

1. `PartView` pede para começar o arraste no `DragDropService`
2. Enquanto o mouse se move, a peça segue o cursor
3. O serviço procura uma carta **compatível** sob o cursor e acende o destaque
4. Ao soltar o botão esquerdo:
   - Se a carta `can_accept` a peça → `try_attach`
   - Senão → a peça não fica na carta (volta / não aceita)

## Regras de aceite (`CharacterSlot.can_accept`)

- A peça não pode ser nula
- O slot daquele tipo ainda está vazio
- O `id` da peça é o mesmo da peça esperada no `CharacterDef`

## Sinais úteis

- `DragDropService.drag_started` / `drag_ended`
- `CharacterSlot.part_attached` / `part_detached`

## Input

Ação configurada no projeto: `pointer_press` (botão esquerdo do mouse).  
O término do arraste também observa soltar o botão esquerdo.
