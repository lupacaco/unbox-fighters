# Sistema: apresentação da luta

A luta de verdade é calculada **antes** de aparecer (`CombatSim`). O `FightDirector` só **mostra** o resultado no palco (a prateleira).

## Sequência

1. Flash na tela. As cartas **sobem e somem**. A loja some.
2. Cada Freak **pula em arco** da carta (ou da direita, se for o oponente) até a prateleira, com um impacto no pouso.
3. **Anda ~6 passos** de perfil até o lugar da fila (1º maior, perto do centro).
4. Placas no topo: nomes, HP e **VS**.
5. Cada choque: a peça **gira, cresce (~2×) e voa em arco** ao centro. Placas douradas com os números. O vencedor mostra o **resto**. O perdedor leva **X** e some. A peça vencedora volta ao corpo.
6. Freak inteiro cai → placa **KO**, inclina e sai. O próximo anda para frente.
7. Fim: EMPATE ou nome + dano. Cartas voltam. Freaks pulam de volta.

## Arquivos

| Peça | Caminho |
|------|---------|
| Regras (números) | `scripts/match/combat_sim.gd` |
| Diretor da sequência | `scripts/assembly/fight_director.gd` |
| Boneco no palco | `scripts/assembly/fighter_puppet.gd` |
| Placas douradas | `scripts/ui/fight_plaque.gd` |
| Overlay antigo (ainda na cena) | `scripts/ui/fight_overlay.gd` |
| Tags coloridas | `scripts/ui/stat_tag.gd` |

## Arte (padrão `-1/-2/-3`)

Em `assets/characters/<nome>/`:

- Frente: `<nome>_head-1.png`, `_body-1`, `_legs-1`
- Perfil: `…-2.png` (usado no palco e na caminhada)
- Ataque: `…-3.png` (usado no choque e no passo)
