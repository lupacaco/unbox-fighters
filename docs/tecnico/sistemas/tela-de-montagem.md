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

1. Desenha o fundo, as duas esteiras, as 2 cartas e as 4 prateleiras
2. Sobe a barra de dinheiro, ATUALIZAR/VENDER e as duas barras de vida
3. Liga o arraste
4. Começa a `LiveMatch` e sorteia **4 caixas**
5. O bot começa a jogar no mesmo ritmo

## Layout (1920×1080)

- **2 cartas** à esquerda (`carta.png`, 306×606)
- **4 prateleiras** no meio (`prateleira-loja.png`)
- **Barra de dinheiro** à direita (10 tijolinhos + `$N`)
- **ATUALIZAR** (azul) e **VENDER** (vermelho) abaixo do dinheiro
- **Esteira azul** embaixo à esquerda, **vermelha** à direita, vão no meio
- Barras de vida no topo: Você à esquerda, Oponente à direita

## Loja

Cada prateleira segura a caixa fechada com o preço. Ao pagar, a caixa abre e o kit fica em cima para arrastar. **ATUALIZAR** troca as caixas fechadas; um kit já pago na prateleira fica.

## Relação com outras cenas

- `Crate` — 1 clique → pede para pagar → some → a prateleira instancia `PartView`
- `CharacterSlot` — recebe 3 kits em cima do caixote; **LUTAR** aparece quando está completo
- `BeltFreak` — o Freak desenhado em cima da esteira
