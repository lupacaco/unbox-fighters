# Sistema: apresentação da luta

A luta de verdade é calculada **antes** de aparecer (`CombatSim`). O `FightDirector` só **mostra** o resultado no palco (a prateleira).

Cada choque sorteia um kit vivo de cada Freak (cabeça, tronco+braços ou pernas). Pode misturar, por exemplo cabeça contra pernas. O desenho no palco tem 6 membros presos nos ímãs (esferas de metal).

## Sequência

1. Flash na tela. As cartas **sobem ~460 px e somem**. A loja e o HUD de cima somem. A câmera se aproxima um pouco.
2. Só **um de cada lado** entra: pulam ao mesmo tempo na prateleira (impacto no pouso) e **andam até ficarem afastados**, um de cada lado do centro. Os outros esperam fora do palco.
3. **Anda** de perfil, em movimento contínuo. Pernas em tempos opostos, braços e cabeça acompanhando, tudo girando no ímã. Leve balanço do tronco. Os dois do duelo ficam **na mesma altura do chão** e do **mesmo tamanho**.

Na luta, quem cobre quem é fixo (não usa o Z da ferramenta de ímãs). Da frente para trás:

1. Cabeça
2. Braço direito
3. Tronco
4. Perna direita
5. Perna esquerda
6. Braço esquerdo

Depois:

4. Placas no topo: nomes, HP e **VS**.
5. Cada choque: **só o kit vencedor** se prepara e **sai do corpo**. A peça perdedora **fica colada** no Freak. O kit voa até o ponto da peça alvo, a tela trava um instante, a câmera treme, faísca e anel de impacto. Aí a peça atingida é **arrancada e arremessada para fora da tela e some**. A que ganha **volta no corpo como um bumerangue**. Se empatar, nenhuma das duas ataca: as duas saem juntas. Placas com os números; o vencedor mostra o **resto**.
6. Freak inteiro cai → placa **KO**, inclina e sai. **Aí** o próximo daquele lado pula no palco e se aproxima. O que ganhou fica esperando.
7. Fim: EMPATE ou nome + dano. Cartas voltam. Quem ainda está de pé pula de volta. Aí a prateleira é limpa.

A poeira dos passos é **um** efeito reaproveitado, não um novo a cada passo. Isso deixa a luta mais leve no computador.

Sons da luta: **só** o passo ao andar e o poom do choque / KO. Sem vento, laser ou clique de ímã no palco.

## Arquivos

| Peça | Caminho |
|------|---------|
| Regras (números) | `scripts/match/combat_sim.gd` |
| Diretor da sequência | `scripts/assembly/fight_director.gd` |
| Boneco no palco | `scripts/assembly/fighter_puppet.gd` |
| Kit arremessado (física) | `scripts/assembly/thrown_kit.gd` |
| Placas douradas | `scripts/ui/fight_plaque.gd` |
| Tags coloridas | `scripts/ui/stat_tag.gd` |

## Arte (padrão `-1/-2`)

Em `assets/characters/<nome>/`:

- Frente: `<nome>_head-1.png`, `_body-1`, `_arm_l-1`, `_arm_r-1`, `_leg_l-1`, `_leg_r-1`
- Perfil: os mesmos com `-2` (usado no palco e na caminhada)

Não precisa de pose de golpe (`-3`). O ataque é o kit vencedor saindo do corpo e voando até a peça do adversário.
