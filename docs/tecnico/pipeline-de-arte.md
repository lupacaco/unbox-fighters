# Pipeline de arte

Scripts fora do Godot que preparam imagens dos personagens.

## Pasta

`tools/`

| Script | Função |
|--------|--------|
| `normalize_parts_300.py` | Limpa fundo preto, centraliza a peça num canvas **300×300** |
| `remove_backgrounds.py` | Remove fundo xadrez / preto de artes de personagem |
| `rig_legs_walk.py` | Coloca ossos nas pernas 3D do policial e grava a animação de passos |

## Convenção de arquivos

Em `assets/characters/<nome>/`:

- `<nome>_head-1.png`, `<nome>_body-1.png`, `<nome>_legs-1.png` — frente
- `<nome>_head-2.png` … — perfil
- `<nome>_head-3.png` … — ataque
- Canvas **300×300**

## Por que 300×300

As cartas posicionam as partes em tamanhos fixos. Normalizar evita peças tortas ou em escalas diferentes. Os scripts em `scripts/core/verify_part_sizes.gd` checam esse padrão.

## Modelos 3D (pernas do policial)

Em `assets/characters/policial/3d/`:

- `policial-legs-3d.glb` — modelo original, parado
- `policial-legs-3d-walk.glb` — o mesmo modelo com ossos e animação de passos

Para gerar de novo: `python tools/rig_legs_walk.py`  
Para ver: `scenes/preview/LegsWalkPreview.tscn` (F6)
