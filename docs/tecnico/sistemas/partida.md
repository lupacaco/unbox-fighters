# Sistema: partida

Regras da partida 1 contra 1. Ficam em `scripts/match/` para poder testar os números **sem** abrir a tela.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `match_rules.gd` | Números fechados: balança ±50, dinheiro, 1 caixa, atualizar grátis, 5 remadas |
| `player_state.gd` | Um lado: carteira, 1 oferta, esteira |
| `live_match.gd` | Tempo correndo: dinheiro, remadas, duelo, balança, fim |
| `belt_lane.gd` | Até 2 Freaks; o da ponta luta, o de trás espera |
| `duel.gd` | Um troca-troca intercalado: o vencedor dá o golpe que mata; se os dois cairiam, os dois atacam |
| `freak_stats.gd` | Poder / Resistência / Agilidade já com sinergia |
| `synergy.gd` | Dupla +25%, tripla +50%, arredonda para cima |
| `fighter_loadout.gd` | Os 3 kits de uma carta |
| `shop_pool.gd` | Sorteia 1 kit entre todos os Freaks |
| `bot_brain.gd` | O oponente compra, monta e manda lutar no mesmo ritmo que você (abrir caixa, encaixar, LUTAR) |

## Fluxo

1. `start` zera os dois lados, enche a loja (1 caixa) e começa o tempo. A balança começa em 0.
2. A cada quadro: dinheiro sobe, Freaks remam (5 passos até a ponta), se os dois estão na ponta começa um troca-troca (a tela mostra um golpe, depois o outro)
3. Se só um está na ponta: 1 ponto por segundo na balança, para o lado de quem está sozinho
4. Balança em −50 (você) ou +50 (oponente) → a partida para e avisa quem ganhou
