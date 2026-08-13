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
- Abrir caixa: 2 cliques, como antes, mas só se tiver 1 pancada.

## Cartas e fila

- 3 cartas, da esquerda para a direita: **3º**, **2º**, **1º**.
- O **1º** (direita) luta primeiro.
- Pode ir incompleto (só pernas, por exemplo). Carta vazia é pulada.
- Arrastar o Freak pelo rótulo **3º/2º/1º** troca a ordem com outra carta.

## Peças

Cada peça ocupa **um** tipo de encaixe:

| Tipo | Significado | Tag |
|------|-------------|-----|
| HEAD | Cabeça | Ameaça (azul) |
| BODY | Tronco | Força (roxo) |
| LEGS | Pernas | Agilidade (verde) |

Cada peça tem **um** número de combate e um **nível** de loja.

| Set | Cabeça | Tronco | Pernas | Total |
|-----|--------|--------|--------|-------|
| Policial | 7 | 6 | 5 | 18 |
| Vampiro | 9 | 9 | 8 | 26 |
| Bruxa | 9 | 4 | 9 | 22 |
| Múmia | 5 | 8 | 6 | 19 |
| Médico | 3 | 4 | 4 | 11 |
| Cachorro | 5 | 5 | 7 | 17 |

Nível da loja pela força da peça: 4–5 → 1; 6 → 2; 7 → 3; 8 → 4; 9 → 5.

## Sinergia (na mesma carta)

Conta quantas peças do **mesmo set** estão na carta. Arredonda para cima.

- 3 iguais: 100%
- 2 iguais: 75%
- 1 só: 50%

Exemplo: cabeça 5 sozinha vira **3**. Completar o set ainda vale muito mais.

## Luta

De cima para baixo: cabeça, senão tronco, senão pernas.

- Se A > B: B morre, A fica A−B e segue.
- Se empatar: as duas partes morrem.
- Quando o Freak inteiro cai, entra o próximo da fila.

Dano no HP do perdedor = soma do que sobrou em cada Freak vivo do vencedor, **no máximo 12 por Freak**.

Na tela: os Freaks **pulam** da carta para a prateleira, **andam** até a fila, e no choque a peça **gira, cresce e voa ao centro**. Placas douradas mostram os números; o vencedor fica com o **resto** (9 contra 5 → 4). Quem perde leva **X** vermelho. Freak inteiro cai → **KO**. As cartas **sobem e somem** durante a batalha e voltam depois.

## Controles

- Mouse: martelo nas caixas; arrastar peças; arrastar carta pelo rótulo 3º/2º/1º; PRONTO; ATUALIZAR; TRAVAR; clicar em NÍVEL para subir a loja.
- Soltar em **VENDER** vende. **Botão direito** no mouse também vende a peça embaixo do cursor.
- Se o encaixe já tem peça, a nova entra e a antiga volta para a prateleira.
- No fim da partida, **NOVA PARTIDA** recomeça.
- Sem gamepad por enquanto.

## O que ainda não é regra

Multiplayer, habilidades de set, freeze por caixa, 4º slot.
