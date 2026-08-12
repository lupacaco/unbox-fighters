# Mecânicas e regras

O que o jogador pode fazer hoje, e as regras que o jogo aplica.

## Fluxo na tela de montagem

1. Aparecem **3 cartas** de personagem e **6 caixas** na prateleira.
2. O jogador abre cada caixa com **2 cliques**:
   - 1º clique → caixa **trincada**
   - 2º clique → caixa **quebrada**, fica 0,5 s e some; aí aparece a **peça**
3. A peça pode ser **arrastada** (segurar o botão esquerdo do mouse e soltar).
4. Se soltar numa carta que **aceita** aquela peça, ela encaixa.
5. Os atributos da carta **somam** os valores das peças encaixadas.
6. Com cabeça + tronco + pernas, o nome deixa de ser `???` e a carta mostra o personagem completo (com brilho).

## Peças

Cada peça ocupa **um** tipo de encaixe:

| Tipo | Significado |
|------|-------------|
| HEAD | Cabeça |
| BODY | Tronco / corpo |
| LEGS | Pernas |

## Atributos (stats)

Cada peça tem três números:

| Código | Nome simples | Exemplo (vampiro) | Exemplo (policial) |
|--------|--------------|-------------------|--------------------|
| BRN | Brain (cérebro / inteligência) | Cabeça 8, Tronco 1, Pernas 0 | Cabeça 6, Tronco 2, Pernas 0 |
| PWR | Power (força) | Cabeça 2, Tronco 9, Pernas 3 | Cabeça 3, Tronco 7, Pernas 4 |
| SPD | Speed (velocidade) | Cabeça 3, Tronco 2, Pernas 8 | Cabeça 4, Tronco 3, Pernas 7 |

**Total do set completo do vampiro:** BRN 9 / PWR 14 / SPD 13  
**Total do set completo do policial:** BRN 8 / PWR 14 / SPD 14

Na carta, os atributos são a **soma** das peças já encaixadas.

## Regras de encaixe

- Só cabe **uma peça por tipo** em cada carta (uma cabeça, um tronco, umas pernas).
- A peça só entra se for a peça **certa daquele personagem** (mesmo `id` da definição do personagem).
- Não dá para colocar cabeça no lugar das pernas, etc.
- Se o drop falhar, a peça volta (não fica “presa” no lugar errado).

## Nome misterioso

Enquanto a carta não estiver completa, o nome mostrado é `???`.  
Quando cabeça + tronco + pernas estão encaixados, o nome real do personagem aparece.

## Botão LUTAR

- Fica **acima da carta**.
- Só aparece se o personagem tiver artes de perfil e ataque (hoje: policial).
- Só libera com as **3 peças** encaixadas.
- Ao clicar: limpa o shelf, o lutador pula até a prateleira, vira de perfil e lança cabeça → tronco → pernas (vai e volta), depois volta à carta.
- Detalhes técnicos: [Animação de luta](../tecnico/sistemas/animacao-de-luta.md).

## Controles atuais

- Mouse: passar por cima da caixa troca o cursor para o martelo; clicar bate (`hammer-02` por 0,2 s). Arrastar e soltar peças.
- Sons acompanham batida, quebra, pegar peça, encaixar, errar e completar o lutador.
- Não há controle de gamepad / teclado de gameplay além disso (por enquanto).

## O que ainda não é regra de jogo

Combate, vida, dano, turnos, multiplayer, economia, inventário persistente e progressão **ainda não existem**.
