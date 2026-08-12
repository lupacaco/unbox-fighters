# Mecânicas e regras

O que o jogador pode fazer hoje, e as regras que o jogo aplica.

## Fluxo na tela de montagem

1. Aparecem **3 cartas** de personagem e **9 caixas** na prateleira.
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

| Código | Nome simples | Vampiro | Policial | Bruxa |
|--------|--------------|---------|----------|-------|
| BRN | Brain (cérebro / inteligência) | 8+1+0 | 6+2+0 | 9+3+1 |
| PWR | Power (força) | 2+9+3 | 3+7+4 | 1+4+2 |
| SPD | Speed (velocidade) | 3+2+8 | 4+3+7 | 4+5+9 |

**Totais (set completo):** vampiro 9/14/13 · policial 8/14/14 · bruxa 13/7/18

Na carta, os atributos são a **soma** das peças já encaixadas.

## Regras de encaixe

- Só cabe **uma peça por tipo** em cada carta (uma cabeça, um tronco, umas pernas).
- Qualquer cabeça/tronco/pernas pode ir em **qualquer carta** (dá para misturar personagens).
- Não dá para colocar cabeça no lugar das pernas, etc.
- Se o drop falhar, a peça volta (não fica “presa” no lugar errado).

## Nome misterioso

Enquanto a carta não estiver completa, o nome mostrado é `???`.  
Quando as 3 peças formam um set conhecido (ex.: só policial), aparece o nome desse personagem.  
Se misturar sets, o nome fica `MIX`.

## Botão LUTAR

- Fica **acima da carta** (em todas as cartas).
- Só libera com as **3 peças** encaixadas **e** com artes de perfil/ataque nessas peças (vampiro, policial e bruxa têm).
- Ao clicar: limpa o shelf → pula no canto esquerdo → anda até o meio intercalando poses → ataca → volta à carta.
- Detalhes técnicos: [Animação de luta](../tecnico/sistemas/animacao-de-luta.md).

## Controles atuais

- Mouse: passar por cima da caixa troca o cursor para o martelo; clicar bate (`hammer-02` por 0,2 s). Arrastar e soltar peças.
- Sons acompanham batida, quebra, pegar peça, encaixar, errar e completar o lutador.
- Não há controle de gamepad / teclado de gameplay além disso (por enquanto).

## O que ainda não é regra de jogo

Combate, vida, dano, turnos, multiplayer, economia, inventário persistente e progressão **ainda não existem**.
