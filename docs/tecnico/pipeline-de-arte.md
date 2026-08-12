# Pipeline de arte

Scripts fora do Godot que preparam imagens dos personagens.

## Pasta

`tools/`

| Script | Função |
|--------|--------|
| `normalize_parts_300.py` | Limpa fundo preto, centraliza a peça num canvas **300×300** |
| `remove_backgrounds.py` | Remove fundo xadrez / preto de artes de personagem |

## Convenção de arquivos

Em `assets/characters/vampiro/` e `assets/characters/policial/`:

- Arquivos finais usados pelo jogo: `head.png`, `body.png`, `legs.png`
- Compostos antigos do vampiro (`full`, `body_head`, `body_legs`) podem sobrar na pasta, mas o jogo não usa mais
- `_src_*` — arte de origem / intermediária do pipeline
- Também podem existir cópias `.webp` das mesmas artes

## Por que 300×300

As cartas posicionam as partes em tamanhos fixos. Normalizar evita peças tortas ou em escalas diferentes. Os scripts em `scripts/core/verify_part_sizes.gd` checam esse padrão (vampiro e policial).
