# Sistema: partida

Regras da partida 1 contra 1 em rodadas. Ficam em `scripts/match/` para poder testar os números **sem** abrir a tela.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `match_rules.gd` | Números fechados: vida 50, 5 de dano por vivo, 60s, $10+$10, 4 prateleiras, atualizar $2, 3 cartas, 5 remadas de 1 s |
| `player_state.gd` | Um lado: carteira, vida, 4 ofertas, 3 cartas, esteira |
| `live_match.gd` | Fases: preparação, luta, resolução (dano e volta), fim |
| `belt_lane.gd` | Até 3 Freaks; o da ponta luta, os de trás esperam com espaço entre os caixotes |
| `duel.gd` | Um troca-troca intercalado: o vencedor dá o golpe que mata; se os dois cairiam, os dois atacam |
| `freak_stats.gd` | Ataque / HP já com bônus de tipo, e o Poder se o set fechou |
| `synergy.gd` | Mesmo tipo nas 2 peças: +50%, arredonda para cima |
| `fighter_loadout.gd` | Os 2 kits de uma carta |
| `shop_pool.gd` | Sorteia 4 kits entre todos os Freaks |
| `bot_brain.gd` | O oponente compra e monta no mesmo relógio de 60s. Só pega um kit se a outra metade ainda cabe no dinheiro (e está na loja). Não gasta $2 para atualizar se depois não dá para montar um Freak |

## Fluxo

1. `start` zera os dois lados (vida 50, $10), enche a loja (4 peças) e começa a **preparação**.
2. Durante a preparação o relógio desce. O bot compra. Ninguém vai para a esteira.
3. No 0 (ou em LUTAR AGORA) começa a **luta**: cópias dos Freaks PRONTO pulam para a esteira; as cartas **não esvaziam**.
4. 5 remadas de 1 s até a ponta. Se os dois estão na ponta, troca-troca de golpes.
5. Quando um lado não tem mais ninguém vivo na esteira, o outro causa `5 × vivos` na vida. Se os dois estavam vazios, 0 dano.
6. A tela devolve os Freaks às cartas e chama `finish_resolution`. Se a vida de alguém chegou a 0, a partida acaba; senão nova preparação com +$10.
