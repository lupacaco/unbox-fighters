# Sistema: partida

Regras da partida 1 contra 1. Ficam em `scripts/match/` para poder testar os números **sem** abrir a tela.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `match_rules.gd` | Números fechados: vida 100, dinheiro, 5 remadas, intervalo por Agilidade |
| `player_state.gd` | Um lado: vida, carteira, 4 ofertas, esteira |
| `live_match.gd` | Tempo correndo: dinheiro, remadas, duelo (pausa enquanto a tela mostra o golpe), chip, fim |
| `belt_lane.gd` | Até 2 Freaks; o da ponta luta, o de trás espera |
| `duel.gd` | Um troca-troca intercalado: o vencedor dá o golpe que mata; se os dois cairiam, os dois atacam |
| `freak_stats.gd` | Poder / Resistência / Agilidade já com sinergia |
| `synergy.gd` | Dupla +25%, tripla +50%, arredonda para cima |
| `fighter_loadout.gd` | Os 3 kits de uma carta |
| `shop_pool.gd` | Sorteia 4 kits entre todos os Freaks |
| `bot_brain.gd` | O oponente compra, monta e manda lutar |

## Fluxo

1. `start` zera os dois lados, enche a loja e começa o tempo
2. A cada quadro: dinheiro sobe, Freaks remam (5 passos até a ponta), se os dois estão na ponta começa um troca-troca (a tela mostra um golpe, depois o outro)
3. Se só um está na ponta: 1 de dano por segundo na vida do outro jogador
4. Vida do jogador em 0 → a partida para e avisa quem ganhou
