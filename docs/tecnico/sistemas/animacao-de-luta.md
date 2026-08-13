# Sistema: apresentação da luta

A luta de verdade é calculada **antes** de aparecer (`CombatSim`). O `FightDirector` só **mostra** o resultado no palco (a prateleira).

## Sequência

1. As peças saltam (cópia visual) para o shelf. As cartas **sobem e somem**.
2. Caixas da loja saem. Título **LUTEM!**, depois **ROUND N**.
3. Dois times no palco: jogador à esquerda, oponente à direita. O 1º fica maior, perto do centro.
4. Cada choque: a peça de cima **cresce e voa ao centro**, aparece **9 > 5**, **X** vermelho em quem morreu.
5. Freak inteiro cai → o próximo da fila chega perto do centro.
6. Número de dano no HP. Cartas **descem e voltam**. Tabuleiro de prep intacto.

## Arquivos

| Peça | Caminho |
|------|---------|
| Regras (números) | `scripts/match/combat_sim.gd` |
| Diretor da sequência | `scripts/assembly/fight_director.gd` |
| Boneco no palco | `scripts/assembly/fighter_puppet.gd` |
| Placar 9 > 5 / X | `scripts/ui/fight_overlay.gd` |
| Tags coloridas | `scripts/ui/stat_tag.gd` |

## Arte (padrão `-1/-2/-3`)

Em `assets/characters/<nome>/`:

- Frente: `<nome>_head-1.png`, `_body-1`, `_legs-1`
- Perfil: `…-2.png` (usado no palco)
- Ataque: `…-3.png` (usado no choque)
