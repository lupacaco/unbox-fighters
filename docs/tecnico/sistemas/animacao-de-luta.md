# Sistema: apresentação da luta

A luta de verdade é calculada **antes** de aparecer (`CombatSim`). O `FightDirector` só **mostra** o resultado no palco (a prateleira).

Há 3 choques: cabeça, tronco, pernas. O desenho no palco tem 6 membros e se mexe como marionete.

## Sequência

1. Flash na tela. As cartas **sobem ~460 px e somem**. A loja e o HUD de cima somem.
2. Cada par (você e o oponente) **pula ao mesmo tempo** até a prateleira, com um impacto no pouso.
3. **Anda ~6 passos** de perfil até o lugar da fila. A cada passo as pernas giram em tempos opostos (uma na frente, a outra atrás) em torno do ímã do quadril. Os braços balançam um pouco. **Não** troca de PNG. Os três ficam **na mesma altura do chão**. O da frente só é desenhado por cima do de trás. Todos do **mesmo tamanho**.
4. Placas no topo: nomes, HP e **VS**.
5. Cada choque: o kit **gira, cresce (~2×) e voa em arco** ao centro. No boneco, o membro do golpe também mexe (tronco = soco do braço da frente; pernas = chute; cabeça = um avanço curto). A câmera aproxima um pouco e o tempo “trava” um instante no impacto. Placas douradas com os números. O vencedor mostra o **resto**. O perdedor leva **X** e some o **kit inteiro**. O kit vencedor volta ao corpo.
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

## Arte (padrão `-1/-2`)

Em `assets/characters/<nome>/`:

- Frente: `<nome>_head-1.png`, `_body-1`, `_arm_l-1`, `_arm_r-1`, `_leg_l-1`, `_leg_r-1`
- Perfil: os mesmos com `-2` (usado no palco e na caminhada)

Não precisa de pose de golpe (`-3`). O ataque é movimento dos membros.
