# Sistema: apresentação da luta

A luta de verdade é calculada em `Duel`. A tela só **mostra** o resultado nas esteiras.

Só a **cabeça** ataca. O Freak não tem pernas: ele desliza puxando o chão com as mãos, sentado no caixote.

## Sequência

1. Você aperta **LUTAR**. O Freak **cai** no começo da esteira (azul à esquerda, vermelha à direita).
2. **Desliza** até a ponta: os braços puxam o chão em ciclo, o corpo balança, sai poeirinha nos rolos.
3. Na ponta: **freia** (esmaga um pouco) e olha para o inimigo. Se já tem alguém na ponta, os dois esperam o intervalo do duelo.
4. **Golpe:** agacha, a cabeça sai, voa em arco com rastro, trava um instante no impacto, o atingido pisca e recua, a cabeça volta como bumerangue.
5. Os dois golpes acontecem; o dano entra depois. Quem zera **perde a cor**, escorrega e **cai no vão** entre as esteiras, girando.
6. Se um lado fica sozinho na ponta: a cada segundo a barra de vida do outro jogador **pula** (1 de dano).

Na luta, quem cobre quem **não** usa o Z da ferramenta de ímãs. **1 fica na frente**.

**De frente** (na carta):

1. Cabeça
2. Braço esquerdo
3. Braço direito
4. Tronco (caixote)

**De perfil** (na esteira):

1. Braço direito
2. Tronco
3. Cabeça
4. Braço esquerdo

Sons da luta: passo no deslize / pouso e poom do golpe. Sem boing de mola.

## Arquivos

| Peça | Caminho |
|------|---------|
| Regras (números) | `scripts/match/duel.gd` |
| Esteira (números) | `scripts/match/belt_lane.gd` |
| Freak na esteira | `scripts/assembly/belt_freak.gd` |
| Cabeça que voa | `scripts/assembly/flying_head.gd` |
| Tags coloridas | `scripts/ui/stat_tag.gd` |

## Arte (padrão `-1/-2`)

Em `assets/characters/<nome>/`:

- Frente: `<nome>_head-1.png`, `_body-1`, `_arm_l-1`, `_arm_r-1`
- Perfil: os mesmos com `-2` (usado na esteira)

Não precisa de pose de golpe (`-3`). O ataque é a cabeça saindo do corpo e voando até a cabeça do adversário.
