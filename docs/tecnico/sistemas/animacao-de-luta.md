# Sistema: apresentação da luta

A luta de verdade é calculada **antes** de aparecer (`CombatSim`). O `FightDirector` só **mostra** o resultado no palco (a prateleira).

## Sequência

1. Flash na tela. As cartas **sobem ~460 px e somem**. A loja e o HUD de cima somem.
2. Cada par (você e o oponente) **pula ao mesmo tempo** até a prateleira, com um impacto no pouso.
3. **Anda ~6 passos** de perfil até o lugar da fila. Os três ficam **na mesma linha do chão** e com o **mesmo tamanho**. O da frente só é desenhado por cima do de trás.
4. Placas no topo: nomes, HP e **VS**.
5. Cada choque: a peça **gira, cresce (~2×) e voa em arco** ao centro. A câmera aproxima um pouco e o tempo “trava” um instante no impacto. Placas douradas com os números. O vencedor mostra o **resto**. O perdedor leva **X** e some. A peça vencedora volta ao corpo.
6. Freak inteiro cai → placa **KO**, inclina e sai. O próximo anda para frente.
7. Fim: EMPATE ou nome + dano. Cartas voltam. Freaks pulam de volta (os que restam, juntos).

A poeira dos passos é **um** efeito reaproveitado, não um novo a cada passo. Isso deixa a luta mais leve no computador.

## Arquivos

| Peça | Caminho |
|------|---------|
| Regras (números) | `scripts/match/combat_sim.gd` |
| Diretor da sequência | `scripts/assembly/fight_director.gd` |
| Boneco no palco | `scripts/assembly/fighter_puppet.gd` |
| Placas douradas | `scripts/ui/fight_plaque.gd` |
| Tags coloridas | `scripts/ui/stat_tag.gd` |

## Arte (padrão `-1/-2/-3`)

Em `assets/characters/<nome>/`:

- Frente: `<nome>_head-1.png`, `_body-1`, `_legs-1`
- Perfil: `…-2.png` (usado no palco e na caminhada)
- Ataque: `…-3.png` (usado no choque e no passo)
