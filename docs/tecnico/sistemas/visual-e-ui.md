# Sistema: visual e UI

Interface da partida. As posições da tela estão em `AssemblyLayout` (1920×1080, origem no canto de cima à esquerda, Y cresce para baixo).

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/assembly/assembly_layout.gd` | Onde cada coisa fica na tela |
| `scripts/ui/game_theme.gd` | Fontes, placas e o visual dos botões |
| `scripts/ui/money_bar.gd` | 10 tijolinhos de ouro + `$N` |
| `scripts/ui/action_bar.gd` | ATUALIZAR (azul) e VENDER (vermelho) |
| `scripts/ui/player_hp_bar.gd` | Nome, barra que esvazia, número |
| `scripts/ui/shop_shelf.gd` | Uma prateleira: caixa fechada ou kit aberto |
| `scripts/ui/stat_tag.gd` | Pílula colorida com o número da peça |
| `scripts/ui/theme_tokens.gd` | Paleta: ouro, creme, azul da esteira, vermelho do oponente |
| `scripts/ui/feel.gd` | Reação gostosa: hover, clique, squash. Esconde retângulo de colisão |
| `scripts/ui/hammer_cursor.gd` | Cursor martelo ao passar / bater nas caixas |

## Cores das tags

- Cabeça (Poder) = vermelho-laranja
- Tronco (Resistência) = roxo
- Braços (Agilidade) = verde

Pílula com sinergia ganha um brilho ouro.

## Arte de UI

Pasta `assets/nova-ui/`:

- `fundo.png` — fundo 1920×1080
- `carta.png` — moldura da carta (306×606)
- `prateleira-loja.png` — prateleira da loja (316×68)
- `esteira-blue.png` / `esteira-red.png` — esteiras (840×129)

Pasta `assets/fonts/`:

- `BebasNeue-Regular.ttf` — títulos e botões
- `Oswald-Variable.ttf` — nomes e frases

Os botões são placas escuras com borda ouro, sombra e texto com contorno. Ao passar o mouse eles crescem um pouco; ao clicar, esmagam. O dinheiro são **tijolinhos** dourados, não bolinhas.

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
