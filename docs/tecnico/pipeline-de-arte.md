# Pipeline de arte

Scripts fora do Godot que preparam imagens dos personagens.

## Pasta

`tools/`

| Script | Função |
|--------|--------|
| `slice_character_sheet.py` | Corta uma folha 6+6 em 12 PNG 200×200 e, se pedido, cria as fichas |
| `normalize_parts_300.py` | Script antigo (canvas 300×200). Não usar nos sets novos |
| `remove_backgrounds.py` | Remove fundo xadrez / preto de artes de personagem |

## Convenção de arquivos

Em `assets/characters/<nome>/`:

- `<nome>_head-1.png`, `_body-1`, `_arm_l-1`, `_arm_r-1`, `_leg_l-1`, `_leg_r-1` — frente
- Os mesmos com `-2` — perfil
- Canvas **200×200**

Para um set novo: [Incluir personagem](incluir-personagem.md). O Godot também tem **Project → Tools → Incluir personagem**.

## Por que 200×200

As peças precisam ter o mesmo tamanho de arquivo para o jogo poder colá-las sem esticar umas e encolher outras. Quadrado 200 × 200. No palco e nas cartas elas aparecem no tamanho 1:1. O script `scripts/core/verify_part_sizes.gd` confere isso.
