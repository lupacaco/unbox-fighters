# Sistema: visual e UI

Interface e apresentação da tela de montagem.

## Arquivos

| Arquivo | Papel |
|---------|--------|
| `scripts/ui/stat_readout.gd` | Mostra nome, BRN / PWR / SPD, total e estado completo |
| `scripts/ui/background_fx.gd` | Fundo de arena, vinheta e poeira |
| `scripts/ui/theme_tokens.gd` | Paleta de cores em constantes (ainda pouco usada) |
| `scripts/ui/hammer_cursor.gd` | Cursor martelo ao passar / bater nas caixas |

## HUD na cena Assembly

- Título e subtítulo (`Assemble your fighters`)
- Em cada carta: `StatReadout` + brilho quando completo (`CompleteGlow`)

## Arte de UI

Pasta `assets/ui/`:

- `bg_premium.png` — fundo
- `frame_premium.png` — moldura da carta
- `shelf_premium.png` — prateleira

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

## Nota

`ThemeTokens` existe para centralizar cores, mas várias cenas ainda usam cores escritas direto no código. Vale unificar no futuro.
