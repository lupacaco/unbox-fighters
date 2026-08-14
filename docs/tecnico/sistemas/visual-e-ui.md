# Sistema: visual e UI

Interface da preparação e da luta. As posições da tela seguem o mesmo mapa da Unity (convertido para o Godot, onde Y cresce para baixo).

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/assembly/assembly_layout.gd` | Onde cada coisa fica na tela (PREP, relógio, loja, vender, cartas) |
| `scripts/ui/prep_hud.gd` | **PREP** no topo, relógio no centro, vs / HP, PRONTO vermelho / NOVA PARTIDA |
| `scripts/ui/shop_bar.gd` | NÍVEL (com custo), 10 bolinhas douradas, ATUALIZAR, TRAVAR |
| `scripts/ui/stat_tag.gd` | Pílula colorida com o número da peça |
| `scripts/ui/fight_plaque.gd` | Placa dourada: nomes, HP, números do choque, KO |
| `scripts/ui/stat_readout.gd` | Nome + números dos 3 kits · total |
| `scripts/ui/background_fx.gd` | Fundo de arena, vinheta e poeira |
| `scripts/ui/theme_tokens.gd` | Paleta: ouro, creme, vermelho do PRONTO, gelo do travar |
| `scripts/ui/hammer_cursor.gd` | Cursor martelo ao passar / bater nas caixas |
| `scripts/assembly/sell_zone.gd` | Área **VENDER +1** à direita; fica dourada quando a peça passa por cima |

Durante a luta, o HUD de cima e a loja somem. Só ficam as placas da luta. No fim: **Você venceu!** ou **Você saiu**.

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
- `shelf_premium.png` — prateleira (vira palco na luta)

As peças dos Freaks são arquivos **200×200**. No jogo todas ficam no mesmo tamanho.

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
