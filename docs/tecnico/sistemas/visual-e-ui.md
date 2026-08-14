# Sistema: visual e UI

Interface da preparação e da luta. As posições da tela seguem o mesmo mapa da Unity (convertido para o Godot, onde Y cresce para baixo).

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/assembly/assembly_layout.gd` | Onde cada coisa fica na tela (PREP, relógio, loja, vender, cartas) |
| `scripts/ui/game_theme.gd` | Fontes, placas douradas e o visual dos botões |
| `scripts/ui/prep_hud.gd` | **PREP** no topo, relógio no centro, vs / HP, PRONTO vermelho / NOVA PARTIDA |
| `scripts/ui/shop_bar.gd` | NÍVEL e ATUALIZAR à esquerda; TRAVAR à direita; 10 bolinhas douradas no topo |
| `scripts/ui/stat_tag.gd` | Pílula colorida com o número da peça |
| `scripts/ui/fight_plaque.gd` | Placa dourada: nomes, HP, números do choque, KO |
| `scripts/ui/stat_readout.gd` | Nome + números da cabeça, tronco e braços · total |
| `scripts/ui/background_fx.gd` | Fundo de arena, vinheta e poeira |
| `scripts/ui/theme_tokens.gd` | Paleta: ouro, creme, vermelho do PRONTO, gelo do travar |
| `scripts/ui/feel.gd` | Reação gostosa: hover, clique, squash. Esconde retângulo de colisão |
| `scripts/ui/hammer_cursor.gd` | Cursor martelo ao passar / bater nas caixas |
| `scripts/assembly/sell_zone.gd` | Área **VENDER +1** à direita; fica dourada quando a peça passa por cima |

Durante a luta, o HUD de cima e a loja somem. O **fundo e a esteira ficam iguais**. Só ficam as placas da luta (nomes, HP e VS no topo). No fim: **Você venceu!** ou **Você saiu**.

## Cores das tags

- Cabeça = azul
- Tronco = roxo
- Braço E = laranja
- Braço D = vermelho-claro
- Perna E = verde
- Perna D = verde-água

## Arte de UI

Pasta `assets/ui/`:

- `bg_premium.png` — fundo
- `frame_premium.png` — moldura da carta
- `esteira-01.png` — esteira no rodapé (palco da luta, 1920 de largura). Caixas e peças ficam coladas nos rolos
- `shelf_premium.png` — prateleira antiga (não usada na tela)

Pasta `assets/fonts/`:

- `BebasNeue-Regular.ttf` — títulos e botões (PREP, PRONTO, NÍVEL…)
- `Oswald-Variable.ttf` — nomes e frases (vs, HP, “Você venceu!”)

Os botões são placas escuras com borda ouro, sombra e texto com contorno. Ao passar o mouse eles crescem um pouco; ao clicar, esmagam. As pancadas são bolinhas douradas, não quadradinhos.

As peças dos Freaks são arquivos **200×200**. No jogo todas ficam no mesmo tamanho.

Ao passar o mouse, clicar ou arrastar, as coisas **crescem, esmagam e brilham** (ouro), sem caixas vermelhas de debug. Regra: `.cursor/rules/feedback-gostoso.mdc`.

## Arte das caixas

Pasta `assets/boxes/`:

- `box-01.png` — fechada
- `box-02.png` — quebrada (aparece no clique)

Com **TRAVAR** ligado, as caixas ficam com um tom gelado (azul-claro).

## Cursor martelo

Pasta `assets/objects/`:

- `hammer-01.png` — mouse em cima da caixa
- `hammer-02.png` — no clique / batida (0,2 s)

Controlado por `HammerCursor` (`scripts/ui/hammer_cursor.gd`).

## Comportamento do fundo

`BackgroundFX` anima uma “respiração” na vinheta e partículas de poeira para dar clima de arena.
