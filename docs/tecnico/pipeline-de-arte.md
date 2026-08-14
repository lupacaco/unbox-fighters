# Pipeline de arte

Scripts fora do Godot que preparam imagens dos personagens.

## Pasta

`tools/`

| Script | Função |
|--------|--------|
| `normalize_parts_300.py` | Limpa fundo preto, centraliza a peça num canvas **300×200** |
| `remove_backgrounds.py` | Remove fundo xadrez / preto de artes de personagem |

## Convenção de arquivos

Em `assets/characters/<nome>/`:

- `<nome>_head-1.png`, `<nome>_body-1.png`, `<nome>_legs-1.png` — frente
- `<nome>_head-2.png` … — perfil
- `<nome>_head-3.png` … — ataque
- Canvas **300×200**

## Por que 300×200

As peças precisam ter o mesmo tamanho de arquivo para o jogo poder aumentar todas iguais. 300 de largura × 200 de altura. No palco e nas cartas elas aparecem com 250 px de largura. O script `scripts/core/verify_part_sizes.gd` confere isso.
