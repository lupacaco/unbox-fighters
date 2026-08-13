# Sistema: partida (auto-battle)

Regras da partida contra bots. Ficam em `scripts/match/` para poder testar os números **sem** abrir a tela.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `match_rules.gd` | Números fechados: HP 40, pancadas, custos, teto 12 |
| `synergy.gd` | 100% / 75% / 50% na mesma carta |
| `fighter_loadout.gd` / `board_loadout.gd` | Uma carta e as 3 cartas em fila |
| `combat_sim.gd` | Choques e dano de HP; devolve eventos |
| `combat_event.gd` / `combat_result.gd` | Cada choque e o placar final |
| `shop_pool.gd` | Sorteia 5 peças do nível da loja |
| `contestant.gd` | Um “jogador”: HP, ouro, loja, tabuleiro |
| `match_state.gd` | Rodada, pareamento (incluindo cópia-fantasma), gastar pancada |
| `fight_pair.gd` | Um confronto da rodada; `right_is_ghost` se o da direita é cópia |
| `bot_brain.gd` | Compras instantâneas dos bots |

## Fluxo

1. `start_match` cria você + 3 bots
2. Cada prep: ouro novo (não acumula), loja, bots compram, pareamento
3. Ao PRONTO ou 60 s: copia as 3 cartas, `CombatSim.simulate`, a tela mostra
4. Os outros bots lutam só nos números (se sobrar 1, ele luta contra uma cópia)
5. HP; quem zera sai; último vivo ganha. **NOVA PARTIDA** recomeça.
