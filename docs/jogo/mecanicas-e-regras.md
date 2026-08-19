# Mecânicas e regras

O que o jogador pode fazer hoje, e as regras que o jogo aplica.

## Loop da partida

Não tem relógio de 60 segundos nem rodadas. O jogo **corre o tempo todo**.

1. Cada jogador começa com **$10**. A barra-balança no **topo** começa **vazia** (o centro é 0). À esquerda está escrito **JOGADOR**, à direita **OPONENTE**.
2. O dinheiro sobe **+$1 a cada 2 segundos**, até **$10**.
3. Você compra kits, monta nas cartas e aperta **LUTAR**.
4. O Freak **pula da carta** para o começo da esteira e vai **remando** com as mãos até a ponta. Lá, luta contra o Freak do oponente.
5. Um Freak sozinho na ponta empurra a **balança** **1 ponto por segundo** para o lado dele (azul para a esquerda, vermelho para a direita).
6. O primeiro que enche **50** no lado dele vence.

Há **1 jogador + 1 oponente**. Derrotar um Freak **não** mexe na balança — só o “beliscão” de 1 por segundo, quando um lado está sozinho na ponta.

## Dinheiro

- Começa a partida com a barra **cheia** ($10).
- Sobe sozinho +$1 a cada 2 s, teto $10.
- **ATUALIZAR** (botão redondo azul) troca a caixa da loja **de graça**. A caixa fechada cai no vão entre as esteiras e uma nova cai na prateleira. Um kit que você já pagou e ainda está na prateleira **não** sai.
- **VENDER** (botão redondo vermelho da lixeira) devolve **metade** do que você pagou, arredondado para cima (pagou $5, recebe $3).

## Loja

- Sempre **1 prateleira**, no meio da tela, com **1 caixa**.
- O oponente tem a mesma regra (1 caixa, atualizar grátis, o mesmo dinheiro), mas a caixa dele **não aparece** — só as cartas vermelhas.
- Cada caixa tem um **preço** escrito embaixo.
- 1 clique paga e abre. A peça fica em cima da prateleira para arrastar. Quando você leva o kit para a carta, uma caixa nova cai sozinha.
- Sem dinheiro suficiente: a caixa treme e a barra de dinheiro também.

## Preço das peças

O preço sai do número da peça, não de um valor solto:

| Kit | Número | Preço |
|-----|--------|-------|
| Cabeça | Ataque 1 a 10 | o próprio Ataque |
| Corpo | HP 10 a 20 | HP − 10 (mínimo $1) |

## Cartas

- **2 cartas azuis** suas à esquerda.
- **2 cartas vermelhas** do oponente à direita: mostram o que ele está encaixando. Você **não** arrasta peças nelas.
- Só vai para a esteira o Freak com **os 2 kits** (cabeça + corpo). Aí aparece o botão **LUTAR** (só nas suas cartas).
- Ao lutar, a carta **esvazia** para montar o próximo. O Freak do oponente também **pula da carta vermelha**.
- Cada esteira cabe **2 Freaks**. Se já tem 2, LUTAR recusa.

## Peças

Nas caixas existem **2 kits**:

| Tipo | O que o jogador recebe | O que isso vale na luta |
|------|------------------------|-------------------------|
| Cabeça | Cabeça | **Ataque** — quanto a cabeça tira de HP por golpe |
| Corpo | Caixote com o tronco e os dois braços | **HP** — a vida daquele Freak |

O corpo **não** é o caixote. O caixote é a **base fixa** da carta e da esteira; o tronco encaixa nele. Não tem pernas e não tem mola. Os braços vêm no corpo; não se compram à parte.

Cada kit tem **um** número. Na carta, as pílulas mostram o número **já com o bônus de tipo**.

| Set | Tipo | Ataque | HP | Custo | Poder (set completo) |
|-----|------|--------|----|-------|----------------------|
| Bruxa | Sobrenatural | 8 | 15 | $8 + $5 = **$13** | Controle de Mente |
| Advogado | Humano | 4 | 18 | $4 + $8 = **$12** | Recurso |

## Tipo e Poder

Cada Freak tem um tipo: **Humano**, **Sobrenatural** ou **Animal**.

- Se as **2 peças** da carta forem do **mesmo tipo**, Ataque e HP ganham **+50%** (arredonda para cima). Vale misturar Freaks diferentes, desde que o tipo bata.
- O **Poder** só liga com **set completo** (cabeça e corpo do **mesmo** Freak). Não é um soco extra: é uma habilidade.

Exemplos:

- Bruxa completa: Ataque **12**, HP **23**, Controle de Mente
- Advogado completo: Ataque **6**, HP **27**, Recurso
- Cabeça da Bruxa + corpo do Advogado: Ataque 8, HP 18, **sem** bônus e **sem** Poder (tipos diferentes)

**Controle de Mente** (Bruxa, 1 vez): depois que ela acerta, o **próximo golpe** daquele inimigo vai no aliado da esteira dele (o da fila). Se não tiver aliado, nada acontece e a carga não gasta.

**Recurso** (Advogado, 1 vez): a primeira vez que o HP ia a 0, ele fica com **1 HP**.

O **preço na loja** continua sendo o número base. O bônus de tipo entra só na hora de lutar.

## Esteira e luta

- Azul = você, da esquerda para o centro. Vermelha = oponente, da direita para o centro. Na vermelha o Freak olha para a esquerda (para o vão).
- Ao apertar **LUTAR**, o Freak **salta da carta** até o começo da esteira.
- Chega na ponta em **5 remadas**. Cada remada: os dois braços sobem para a frente, jogam para trás em meia-lua, e **só então** o caixote desliza (com fumacinha atrás). Depois os braços ficam para baixo **2 segundos** até a próxima remada. Todo mundo rema no mesmo ritmo. A ponta fica **em cima dos rolos**, não por cima do buraco.
- Só o Freak da **ponta** luta. O de trás espera com um vão entre os caixotes, para não grudar.
- Na esteira aparecem as etiquetas de **Ataque** (cabeça) e **HP** (corpo), iguais às da carta.
- Só a **cabeça** ataca: pula, voa, bate e volta. O número do dano sobe do Freak atingido.
- Os golpes são **um de cada vez**. Primeiro um ataca e causa o dano; se ninguém caiu, o outro responde.
- O golpe que **mata** é sempre do que vai vencer. Se o troca-troca mataria os dois, a ordem é sorteada e **os dois atacam**.
- Quem zera a vida do Freak escorrega e **cai no vão** entre as esteiras.

O oponente usa **as mesmas regras** que você: o mesmo dinheiro, 1 caixa, atualizar grátis, 2 cartas. Ele também gasta tempo para abrir a caixa, encaixar o kit e apertar LUTAR — não monta um Freak no primeiro segundo.

## Controles

- Mouse: martelo nas caixas; arrastar peças para as cartas **azuis**; botão redondo de **atualizar**; clicar numa peça e no botão da **lixeira** (ou arrastar até ele).
- Se o encaixe já tem peça, a nova entra e a antiga volta para a prateleira.
- Sem gamepad por enquanto.

## O que ainda não é regra

Multiplayer, menus, salvamento.
