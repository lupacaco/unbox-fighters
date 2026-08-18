# Pipeline de arte

Scripts fora do Godot que preparam imagens dos personagens.

## Pasta

`tools/`

| Script | Função |
|--------|--------|
| `slice_character_sheet.py` | Corta uma folha 4+4 em 8 PNG 200×200 e grava `{id}_slice.json` com os ímãs |
| `scripts/core/import_roster.gd` | Lê cada `_slice.json` e cria as fichas em `data/parts/` |
| `remove_backgrounds.py` | Remove fundo xadrez / sólido de artes de UI |
| `fetch_sfx.py` | Baixa e recorta os efeitos sonoros gravados (Mixkit) |
| `run_checks.ps1` | Roda todos os `verify_*.gd` sem abrir a janela do jogo |

## Convenção de arquivos

Em `assets/characters/<nome>/`:

- `<nome>_head-1.png`, `_body-1`, `_arm_l-1`, `_arm_r-1` — frente
- Os mesmos com `-2` — perfil
- `<nome>_slice.json` — ímãs e números que o cortador achou
- Canvas **200×200**

Para um set novo: [Incluir personagem](incluir-personagem.md). O Godot também tem **Project → Tools → Incluir personagem** (corta os 8 PNG e cria os 3 kits da loja).

## Por que 200×200

As peças precisam ter o mesmo tamanho de arquivo para o jogo poder colá-las sem esticar umas e encolher outras. Quadrado 200 × 200. No palco e nas cartas elas aparecem no tamanho 1:1. O script `scripts/core/verify_part_sizes.gd` confere isso.
