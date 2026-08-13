# Sistema: visual e UI

Interface da preparação e da luta.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/ui/prep_hud.gd` | **PREP.** / **LUTA**, relógio `1:00`, vs oponente, HP dos 4, PRONTO / NOVA PARTIDA |
| `scripts/ui/shop_bar.gd` | NÍVEL, bolinhas de pancadas, ATUALIZAR, TRAVAR |
| `scripts/ui/stat_tag.gd` | Pílula colorida com o número da peça |
| `scripts/ui/fight_overlay.gd` | Overlay antigo da luta (a apresentação nova usa placas) |
| `scripts/ui/fight_plaque.gd` | Placa dourada: nomes, HP, números do choque, KO |
| `scripts/ui/stat_readout.gd` | Nome e total na carta |
| `scripts/ui/background_fx.gd` | Fundo de arena, vinheta e poeira |
| `scripts/ui/theme_tokens.gd` | Paleta: laranja PREP, azul / roxo / verde das tags, vermelho das pancadas |
| `scripts/ui/hammer_cursor.gd` | Cursor martelo ao passar / bater nas caixas |

## Cores das tags

- Cabeça / Ameaça = azul
- Tronco / Força = roxo
- Pernas / Agilidade = verde

## Arte de UI

Pasta `assets/ui/`:

- `bg_premium.png` — fundo
- `frame_premium.png` — moldura da carta
- `shelf_premium.png` — prateleira (vira palco na luta)

## Arte das caixas

Pasta `assets/boxes/`:

- `box-01.png` — intacta
- `box-02.png` — trincada
- `box-03.png` — quebrada

## Cursor martelo

Pasta `assets/objects/`:

- `hammer-01.png` — mouse em cima da caixa
- `hammer-02.png` — no clique / batida (0,2 s)

Controlado por `HammerCursor` (`scripts/ui/hammer_cursor.gd`).

## Comportamento do fundo

`BackgroundFX` anima uma “respiração” na vinheta e partículas de poeira para dar clima de arena.
