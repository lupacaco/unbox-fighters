# Sistema: apresentação da luta

A luta de verdade é calculada em `Duel`. A tela só **mostra** o resultado nas esteiras.

Só a **cabeça** ataca. O Freak não tem pernas: ele **rema** com as duas mãos, sentado no caixote.

## Sequência

1. Você aperta **LUTAR**. O Freak **salta da carta** em arco até o começo da esteira (azul à esquerda). O oponente **salta da carta vermelha** até o começo da vermelha.
2. **Rema** até a ponta em **5 remadas**. Na esteira o braço fica **esticado para a frente**. Cada remada: meia-lua para trás (frente → baixo → trás) para pegar impulso; **aí** o caixote desliza (som de madeira e fumacinha) enquanto os braços voltam (trás → baixo → frente). Depois espera **2 segundos** com o braço de novo para a frente. Os braços ficam **na frente** dos números do caixote.
3. Na ponta: **freia** (esmaga um pouco), ainda em cima da esteira. Se já tem alguém na ponta, os dois esperam o intervalo do duelo. O de trás fica com um vão entre os caixotes.
4. **Golpe:** agacha, a cabeça sai, voa em arco com rastro, trava um instante no impacto, o atingido pisca, recua e mostra o número do dano, a cabeça volta como bumerangue.
5. Os golpes são **um de cada vez**. Se o primeiro não derrubou ninguém, o outro responde. O golpe que mata é sempre do vencedor. Se os dois cairiam, os dois atacam.
6. Quem zera **perde a cor**, escorrega e **cai no vão** entre as esteiras, girando.
7. Se um lado fica sozinho na ponta: a cada segundo a barra-balança **pula** 1 ponto para o lado dele.

Na esteira, o Freak do oponente fica virado para a esquerda (para o vão). O seu fica virado para a direita.

No caixote aparecem o nome, o Ataque e o HP, com os ícones grandes. O HP **diminui** no painel quando leva golpe.

Na luta, quem cobre quem **não** usa o Z da ferramenta de ímãs. **1 fica na frente**.

**De frente** (na carta):

1. Cabeça
2. Braço esquerdo
3. Braço direito
4. Tronco (encaixado no caixote; a faixa de cima do caixote fica atrás, a caixa de baixo na frente)

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
| Placa do caixote | `scripts/ui/crate_plaque.gd` |

## Arte (padrão `-1/-2`)

Em `assets/characters/<nome>/`:

- Frente: `<nome>_head-1.png`, `_body-1`, `_arm_l-1`, `_arm_r-1`
- Perfil: os mesmos com `-2` (usado na esteira)

Não precisa de pose de golpe (`-3`). O ataque é a cabeça saindo do corpo e voando até a cabeça do adversário.
