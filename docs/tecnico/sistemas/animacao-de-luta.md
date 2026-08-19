# Sistema: apresentação da luta

A luta de verdade é calculada em `Duel`. A tela só **mostra** o resultado nas esteiras.

Só a **cabeça** ataca. O Freak não tem pernas: ele **rema** com as duas mãos, sentado no caixote.

## Sequência

1. Você aperta **LUTAR**. O Freak **salta da carta** em arco até o começo da esteira (azul à esquerda). O oponente **salta da carta vermelha** até o começo da vermelha.
2. **Rema** até a ponta em **5 remadas**. Cada remada: os dois braços sobem para a frente, jogam para trás em meia-lua, **aí** o caixote desliza (som de madeira no chão e fumacinha atrás). Depois os braços caem e esperam **2 segundos**.
3. Na ponta: **freia** (esmaga um pouco). Se já tem alguém na ponta, os dois esperam o intervalo do duelo.
4. **Golpe:** agacha, a cabeça sai, voa em arco com rastro, trava um instante no impacto, o atingido pisca, recua e mostra o número do dano, a cabeça volta como bumerangue.
5. Os golpes são **um de cada vez**. Se o primeiro não derrubou ninguém, o outro responde. O golpe que mata é sempre do vencedor. Se os dois cairiam, os dois atacam.
6. Quem zera **perde a cor**, escorrega e **cai no vão** entre as esteiras, girando.
7. Se um lado fica sozinho na ponta: a cada segundo a barra-balança **pula** 1 ponto para o lado dele.

Na esteira, o Freak do oponente fica virado para a esquerda (para o vão). O seu fica virado para a direita.

Na esteira aparecem as etiquetas coloridas de **Ataque** na cabeça e **HP** no tronco, iguais às da carta.

Na luta, quem cobre quem **não** usa o Z da ferramenta de ímãs. **1 fica na frente**.

**De frente** (na carta):

1. Cabeça
2. Braço esquerdo
3. Braço direito
4. Tronco (encaixado no caixote)

**De perfil** (na esteira):

1. Braço direito
2. Tronco
3. Cabeça
4. Braço esquerdo

Sons da luta: passo no pulo, raspar curto de madeira no deslize, poom do golpe. Sem boing de mola.

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
