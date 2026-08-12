# Pipeline de arte

Scripts fora do Godot que preparam imagens dos personagens.

## Pasta

`tools/`

| Script | Função |
|--------|--------|
| `normalize_parts_300.py` | Limpa fundo preto, centraliza a peça num canvas **300×300** |
| `remove_backgrounds.py` | Remove fundo xadrez / preto de artes de personagem |

## Convenção de arquivos

Em `assets/characters/<nome>/`:

- `<nome>_head-1.png`, `<nome>_body-1.png`, `<nome>_legs-1.png` — frente
- `<nome>_head-2.png` … — perfil
- `<nome>_head-3.png` … — ataque
- Canvas **300×300**

## Por que 300×300

As cartas posicionam as partes em tamanhos fixos. Normalizar evita peças tortas ou em escalas diferentes. Os scripts em `scripts/core/verify_part_sizes.gd` checam esse padrão.
