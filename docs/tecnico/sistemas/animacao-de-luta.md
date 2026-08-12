# Sistema: animação de luta (provisório)

Por enquanto **não há oponente**. O botão **LUTAR** só mostra uma animação de showcase no shelf (a prateleira).

## Quando o botão libera

- Aparece em **todas** as cartas.
- Só fica clicável quando a carta está **completa** e as 3 peças encaixadas têm poses de perfil e ataque (hoje: set do policial).

## Sequência ao clicar

1. Peças soltas e caixas do shelf **deslizam para fora** da tela e somem (peças já encaixadas nas cartas **não** são apagadas).
2. O lutador **pula** da carta e **cai com força** no **canto esquerdo** do shelf (vista de frente).
3. Vira de **perfil** (`sprite_profile` / pose `-2`).
4. **Anda até o meio** do shelf. A cada passo, as 3 partes intercalam `-2` e `-3` (`sprite_profile` ↔ `sprite_attack`).
5. Para no meio com todas em `-2`.
6. Lança como bumerangue (vai e volta), nesta ordem:
   - cabeça (`sprite_attack`)
   - tronco
   - pernas
7. Pula de volta para a carta.

## Arquivos

| Peça | Caminho |
|------|---------|
| Diretor da sequência | `scripts/assembly/fight_director.gd` |
| Boneco temporário no stage | `scripts/assembly/fighter_puppet.gd` |
| Botão na carta | `CharacterSlot` → nó `FightButton` |
| Dados das poses | `PartDef.sprite_profile` / `PartDef.sprite_attack` |

## Arte (policial)

Em `assets/characters/policial/`:

- Frente: `head.png`, `body.png`, `legs.png`
- Perfil: `head_profile.png`, `body_profile.png`, `legs_profile.png`
- Ataque: `head_attack.png`, `body_attack.png`, `legs_attack.png`
