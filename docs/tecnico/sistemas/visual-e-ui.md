# Sistema: visual e UI

Interface da partida. As posições da tela estão em `AssemblyLayout` (1920×1080, origem no canto de cima à esquerda, Y cresce para baixo).

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/assembly/assembly_layout.gd` | Onde cada coisa fica na tela |
| `scripts/ui/game_theme.gd` | Fontes, placas e o visual dos botões |
| `scripts/ui/money_bar.gd` | 10 tijolinhos de ouro + `$N` |
| `scripts/ui/action_bar.gd` | Botão redondo de atualizar e lixeira de vender |
| `scripts/ui/tug_bar.gd` | Barra-balança no topo: JOGADOR / OPONENTE, azul à esquerda, vermelho à direita |
| `scripts/ui/shop_shelf.gd` | Uma prateleira: caixa fechada ou kit aberto |
| `scripts/ui/stat_tag.gd` | Pílula colorida com o número da peça |
| `scripts/ui/theme_tokens.gd` | Paleta: ouro, creme, azul da esteira, vermelho do oponente |
| `scripts/ui/feel.gd` | Reação gostosa: hover, clique, squash. Esconde retângulo de colisão |
| `scripts/ui/hammer_cursor.gd` | Cursor martelo ao passar / bater nas caixas |

## Cores das tags

- Cabeça (Ataque) = vermelho-laranja
- Corpo (HP) = roxo

Pílula com sinergia ganha um brilho ouro.

## Arte de UI

Pasta `assets/nova-ui/`:

- `fundo.png` — fundo 1920×1080
- `carta.png` — moldura da carta sua (306×572)
- `carta-oponente.png` — moldura da carta do oponente (306×571)
- `prateleira-loja.png` — prateleira da loja (438×95)
- `atualizar.png` / `vender.png` — botões redondos (216×216)
- `barra-hp-vazia.png` — tubo da balança (819×149)
- `liquido-jogador.png` / `liquido-oponente.png` — líquidos azul e vermelho (349×62)
- `caixote.png` — base de madeira de todos os Freaks (301×201)

Pasta `assets/fonts/`:

- `BebasNeue-Regular.ttf` — títulos e botões
- `Oswald-Variable.ttf` — nomes e frases

Os botões da loja são os círculos da arte, sem texto “ATUALIZAR $1”. Ao passar o mouse eles crescem um pouco; ao clicar, esmagam. O dinheiro são **tijolinhos** dourados ao lado da prateleira.

A barra-balança fica **no topo**, no meio da tela. Começa vazia. O líquido azul cresce do centro para a esquerda; o vermelho, para a direita. Nunca os dois ao mesmo tempo. Cada +1 dá um pulso gostoso. No lado azul está escrito **JOGADOR**; no vermelho, **OPONENTE**. A barra é um pouco menor que a arte original.

A caixa da loja é grande (cerca de 280 px de altura) e senta no centro, entre as quatro cartas.

As peças dos Freaks são arquivos **200×200**. No jogo todas ficam no mesmo tamanho.

Ao passar o mouse, clicar ou arrastar, as coisas **crescem, esmagam e brilham** (ouro), sem caixas vermelhas de debug. Regra: `.cursor/rules/feedback-gostoso.mdc`.

## Arte das caixas

Pasta `assets/boxes/`:

- `box-01.png` — fechada
- `box-02.png` — quebrada (aparece no clique)

## Cursor martelo

Pasta `assets/objects/`:

- `hammer-01.png` — mouse em cima da caixa
- `hammer-02.png` — no clique / batida (0,2 s)

Controlado por `HammerCursor` (`scripts/ui/hammer_cursor.gd`).
