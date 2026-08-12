# Sistema: animação de luta (provisório)

Por enquanto **não há oponente**. O botão **LUTAR** só mostra uma animação de showcase no shelf (a prateleira).

## Quando o botão aparece

- Só em personagens que têm poses de **perfil** e **ataque** nas 3 peças (hoje: policial).
- Só fica clicável quando a carta está **completa** (cabeça + tronco + pernas).

## Sequência ao clicar

1. Peças e caixas do shelf **deslizam para fora** da tela e somem.
2. O lutador **pula** da carta e **cai com força** no shelf (vista de frente).
3. Espera **2 s**.
4. Troca para vista de **perfil** (sprites `-2` / `sprite_profile`).
5. Espera **2 s**.
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
