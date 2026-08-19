# Sistema: tela de montagem

A cena principal do jogo hoje: a mesma sala troca de **preparação** para **luta**.

## Arquivos

| Tipo | Caminho |
|------|---------|
| Cena | `scenes/assembly/Assembly.tscn` |
| Controlador | `scripts/assembly/assembly_controller.gd` (`AssemblyController`) |
| Posições | `scripts/assembly/assembly_layout.gd` |
| Cenas filhas | `CharacterSlot.tscn`, `PartView.tscn` |

## O que o controlador faz ao iniciar

1. Desenha o fundo, as duas esteiras, as 3 cartas suas, as 3 cartas do oponente (escondidas) e 4 prateleiras
2. Sobe o dinheiro em círculo, os botões redondos (mesmo tamanho), as barras de vida nos cantos e o relógio de 60s
3. Liga o arraste (só nas cartas azuis, só na preparação)
4. Começa a `LiveMatch` e sorteia **4 peças**
5. O bot compra e monta no mesmo relógio

## Layout (1920×1080)

- **3 cartas azuis** à esquerda (`carta.png`, 306×572, um pouco menores para caber), coladas no topo
- **3 cartas vermelhas** à direita (`carta-oponente.png`) — só na luta, no lugar da loja
- **4 prateleiras** em grade 2×2 à direita na preparação (`prateleira-loja.png`); atualizar, lixeira e dinheiro à direita delas
- **Esteira azul** embaixo à esquerda, **vermelha** à direita, vão no meio; os Freaks param em cima dos rolos; até três na mesma esteira com espaço entre os caixotes
- **Barras de vida** em pé nos cantos (`barra-hp-vazia.png` + líquidos). Escreve **JOGADOR** / **OPONENTE** e o número ao lado, em pé
- **Relógio 60s** no vão entre as esteiras; botão **LUTAR AGORA** acima

## Loja

A prateleira já mostra o kit e o preço. Arrastar para a carta **paga**. **Atualizar** ($2) joga as ofertas no vão e sorteia de novo. Um kit já pago na prateleira fica. Comprar **não** enche a prateleira de graça.

## Relação com outras cenas

- `PartView` — kit arrastável; na loja vem com etiqueta de preço
- `CharacterSlot` — recebe 2 kits; o caixote (duas partes) já está na carta (mesmo tamanho vazio ou com peças); **PRONTO** aparece quando está completo
- `BeltFreak` — o Freak na esteira: pula da carta com o braço para a frente, rema 5 vezes em meia-lua; no nocaute esfria e no fim da luta volta para a carta
