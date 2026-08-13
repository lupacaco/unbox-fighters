# Testes rápidos (headless)

Scripts que verificam partes do jogo **sem** você jogar na tela.  
“Headless” = roda o Godot sem a janela completa de jogo, só para checar.

## Onde ficam

`scripts/core/`

| Script | O que verifica |
|--------|----------------|
| `verify_synergy.gd` | 100/75/50, números dos 3 sets, curva de pancadas |
| `verify_combat_sim.gd` | Choque, empate, teto de 12 de dano no HP |
| `verify_shop_pool.gd` | Loja nível 1 não vende 9; 5 ofertas |
| `verify_match_state.gd` | 4 vivos, HP 40, 3 bots, oponente na rodada 1 |
| `verify_assembly.gd` | 3 cartas e 5 caixas |
| `verify_crate_open.gd` | Fluxo de 2 cliques da caixa |
| `verify_composite.gd` | Layout por ímãs |
| `verify_part_sizes.gd` | Sprites 300×300 e poses |
| `verify_fight_poses.gd` | Personagens têm poses; carta aceita qualquer set |
| `verify_fight_lock.gd` | Travamento da carta ainda enxerga as peças anexadas |
| `debug_parts.gd` | Carrega peça e checa visibilidade do sprite |
| `debug_reveal.gd` | Força revelar peça da caixa e checa transparência |

## Quando atualizar

Se mudar a tela, a loja, a sinergia, a luta, as caixas ou a arte, revise estes scripts e este doc.
