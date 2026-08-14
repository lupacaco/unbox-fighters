# Mecânicas e regras

O que o jogador pode fazer hoje, e as regras que o jogo aplica.

## Loop da partida

1. **Preparação** (até 60 segundos, ou aperte **PRONTO**).
2. **Luta** contra 1 oponente (os outros dois bots lutam entre si, sem você ver).
3. Quem toma dano no HP. Quem chega a 0 sai.
4. Volta à preparação com as peças das cartas **intactas** (a luta usa uma cópia).
5. O último com HP ganha.

Há **1 jogador + 3 bots** (Sombra, Ferrugem, Névoa). HP inicial **40**. Não enfrenta o mesmo oponente duas vezes seguidas, se der. Com 3 vivos, o bot que sobra luta contra uma **cópia** do oponente do jogador: se a cópia perde, o oponente de verdade **não** perde vida.

## Pancadas (o “ouro”)

- Rodada 1: **3**. Sobe **+1 por rodada**, máximo **10**.
- O que sobrar **não** junta com a próxima rodada.
- Gastos: quebrar caixa **1**, atualizar loja **1**, subir nível da loja **4 / 5 / 6 / 7** (níveis 1→5).
- **Travar** é de graça: as 5 caixas atuais ficam no próximo round.
- **Vender** uma peça (ou o Freak inteiro) devolve **1** pancada.

## Loja

- Sempre **5 caixas**. Peças do **nível da loja** (e abaixo).
- Nível 1 não vende peça 9.
- ATUALIZAR = nova leva, custa 1, solta o travar.
- Abrir caixa: **1 clique**, custa 1 pancada.

## Cartas e fila

- 3 cartas, da esquerda para a direita: **3º**, **2º**, **1º**.
- O **1º** (direita) luta primeiro.
- Pode ir incompleto (só a cabeça, por exemplo). Carta vazia é pulada.
- Arrastar o Freak pelo rótulo **3º/2º/1º** troca a ordem com outra carta.

## Peças

Nas caixas existem **4 kits**. Cada um ocupa um encaixe da carta:

| Tipo | O que o jogador recebe | Tag |
|------|------------------------|-----|
| HEAD | Cabeça | Azul |
| BODY | Tronco (sem os braços) | Roxo |
| ARM_L | Braço esquerdo (de quem olha) | Laranja |
| ARM_R | Braço direito (de quem olha) | Vermelho-claro |

Toda carta já tem uma **base-mola**. Ela não sai da carta, não vem na caixa e **não tem número** de luta. Em cima da mola tem uma esfera de metal: é o ímã onde a peça senta.

- Carta vazia: mola **solta** (alta).
- Qualquer peça encaixada: mola **pressionada** (baixa).
- Só a cabeça: a cabeça cola na esfera da mola.
- Cabeça + tronco: o tronco cola na esfera; a cabeça cola no pescoço do tronco (como já era).
- Braço com tronco: cola no ombro. Sem tronco: senta na mola, um pouco para o lado.

Não dá para tirar a mola. Não dá para encaixar pernas — o jogo não vende pernas.

Cada kit da loja tem **um** número de combate e um **nível** de loja.

| Set | Kits | Total |
|-----|------|-------|
| Leão | Cabeça 4, tronco 4, braço E 4, braço D 4 (nível 1) | 16 |
| Médico | Cabeça 5 (nível 1); tronco 6 e os dois braços 6 (nível 2) | 23 |
| Vampiro | Cabeça 3, tronco 4, braço E 4, braço D 4 (nível 1) | 15 |
| Bruxa | Cabeça 4, tronco 3, braço E 3, braço D 3 (nível 1) | 13 |

Nível da loja pela força do kit: 3–5 → 1; 6 → 2; 7 → 3; 8 → 4; 9 → 5.

## Sinergia (na mesma carta)

Conta quantos kits do **mesmo set** estão na carta. Arredonda para cima.

- 2 iguais: 100%
- 1: 50%

Exemplo: cabeça 4 sozinha vira **2**. Cabeça + tronco do mesmo set já vale o número cheio (8 no leão). Os dois braços iguais somam mais (set completo do leão = **16**).

## Luta

Cada choque sorteia **um kit vivo de cada lado**. Pode ser cabeça contra braço, tronco contra cabeça, etc. Não segue ordem fixa. Pula o que estiver vazio.

- Se A > B: só A ataca. B fica no corpo até levar o golpe e voar para fora. A fica A−B e pode ser sorteada de novo.
- Se empatar: os dois kits morrem. Na tela os dois atacam juntos, batem no centro e voam para fora.
- Quando o Freak inteiro cai, entra o próximo da fila.

Dano no HP do perdedor = soma do que sobrou em cada Freak vivo do vencedor, **no máximo 12 por Freak**.

Na tela: entra **um contra um**. O 1º de cada lado **pula** na esteira e **dá dois pulos** até o lugar do ataque: a mola aperta, impulsiona, o brinquedo inteiro sai do chão e cai. Só quando um cai inteiro (**KO**) o próximo daquele lado pula e se aproxima. No choque, **só o kit que vai ganhar** sai do corpo e voa até a peça do outro. A que perde **fica colada** até o impacto; aí **voa para fora da tela e some**. A que ganha volta no corpo como bumerangue. Se os números forem iguais, **os dois atacam**, batem no centro e os dois voam para fora. As placas mostram os números. As cartas **sobem e somem** durante a batalha e voltam depois.

## Controles

- Mouse: martelo nas caixas; arrastar peças; arrastar carta pelo rótulo 3º/2º/1º; PRONTO; ATUALIZAR; TRAVAR; clicar em NÍVEL para subir a loja.
- Soltar em **VENDER** (direita da esteira) vende. **Botão direito** no mouse também vende a peça embaixo do cursor.
- Se o encaixe já tem peça, a nova entra e a antiga volta para a esteira.
- No fim da partida, **NOVA PARTIDA** recomeça.
- Sem gamepad por enquanto.

## O que ainda não é regra

Multiplayer, habilidades de set, freeze por caixa, 4º slot.
