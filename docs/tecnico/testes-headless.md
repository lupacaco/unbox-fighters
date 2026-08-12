# Testes rápidos (headless)

Scripts que verificam partes do jogo **sem** você jogar na tela.  
“Headless” = roda o Godot sem a janela completa de jogo, só para checar.

## Onde ficam

`scripts/core/`

| Script | O que verifica |
|--------|----------------|
| `verify_assembly.gd` | Se nascem 3 cartas e 9 caixas |
| `verify_crate_open.gd` | Fluxo de 2 cliques da caixa (`box-01` → `box-02` → `box-03` → peça) |
| `verify_composite.gd` | Layout por ímãs (ordem cabeça / tronco / pernas) |
| `verify_part_sizes.gd` | Sprites 300×300, poses e modo layered (vampiro + policial + bruxa) |
| `verify_fight_poses.gd` | Todos os personagens têm poses; botão LUTAR na carta |
| `verify_fight_lock.gd` | Luta usa peças anexadas mesmo se a carta já estiver travada |
| `verify_model_3d.gd` | GLBs do policial carregam com pintura visível (sem material “metal preto”) |
| `debug_parts.gd` | Carrega peça e checa visibilidade do sprite |
| `debug_reveal.gd` | Força revelar peça da caixa e checa transparência |

## Quando atualizar

Se mudar a tela de montagem, abertura da caixa, ímãs das peças, composição visual, tamanhos de arte ou o fluxo da peça, revise estes scripts e este doc.
