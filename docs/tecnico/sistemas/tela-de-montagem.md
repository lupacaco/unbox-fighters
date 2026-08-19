# Sistema: tela de montagem

A cena principal do jogo hoje: loja + cartas + esteiras no mesmo palco.

## Arquivos

| Tipo | Caminho |
|------|---------|
| Cena | `scenes/assembly/Assembly.tscn` |
| Controlador | `scripts/assembly/assembly_controller.gd` (`AssemblyController`) |
| Posições | `scripts/assembly/assembly_layout.gd` |
| Cenas filhas | `CharacterSlot.tscn`, `Crate.tscn`, `PartView.tscn` |

## O que o controlador faz ao iniciar

1. Desenha o fundo, as duas esteiras, as 2 cartas suas, as 2 cartas do oponente e 1 prateleira
2. Sobe o dinheiro ao lado da prateleira, os botões redondos e a barra-balança no topo, no meio
3. Liga o arraste (só nas cartas azuis)
4. Começa a `LiveMatch` e sorteia **1 caixa**
5. O bot começa a jogar no mesmo ritmo: espera, abre caixa, encaixa, só então LUTAR

## Layout (1920×1080)

- **2 cartas azuis** à esquerda (`carta.png`, 306×572), coladas no topo (os ganchos das correntes tocam a borda de cima), espelhadas com as vermelhas
- **2 cartas vermelhas** à direita (`carta-oponente.png`) — só mostram a montagem do oponente
- **1 prateleira** no centro da tela (`prateleira-loja.png`, 438×95); atualizar e lixeira à esquerda, dinheiro à direita
- Caixa da loja com **280 px** de altura
- **Esteira azul** embaixo à esquerda, **vermelha** à direita, vão no meio; os Freaks na esteira ficam quase do tamanho da carta (85%)
- **Barra-balança** no topo, no meio, no vão entre as cartas de dentro (`barra-hp-vazia.png`, 70% do tamanho). Escreve **JOGADOR** no líquido azul (esquerda) e **OPONENTE** no vermelho (direita)

## Loja

A prateleira segura a caixa fechada com o preço. Ao pagar, a caixa abre e o kit fica em cima para arrastar. **Atualizar** joga a caixa fechada no vão e deixa cair uma nova. Um kit já pago na prateleira fica. Quando o kit vai para a carta, uma caixa nova cai sozinha.

## Relação com outras cenas

- `Crate` — 1 clique → pede para pagar → some → a prateleira instancia `PartView`
- `CharacterSlot` — recebe 2 kits em cima do caixote; **LUTAR** aparece quando está completo (cartas do oponente não têm LUTAR e não aceitam o seu arraste)
- `BeltFreak` — o Freak na esteira: pula da carta, rema 5 vezes, mostra Ataque e HP nas partes
