# Testes rápidos (headless)

Scripts que verificam partes do jogo **sem** você jogar na tela.  
“Headless” = roda o Godot sem a janela completa de jogo, só para checar.

## Onde ficam

`scripts/core/`

| Script | O que verifica |
|--------|----------------|
| `verify_assembly.gd` | Se nascem 3 cartas e 5 caixas |
| `verify_crate_open.gd` | Fluxo de 2 cliques da caixa (`box-01` → `box-02` → `box-03` → peça) |
| `verify_composite.gd` | Lógica do `CompositeResolver` |
| `verify_part_sizes.gd` | Sprites 300×300 e modos do resolver |
| `debug_parts.gd` | Carrega peça e checa visibilidade do sprite |
| `debug_reveal.gd` | Força revelar peça da caixa e checa transparência |

## Quando atualizar

Se mudar a tela de montagem, abertura da caixa, composição visual, tamanhos de arte ou o fluxo da peça, revise estes scripts e este doc.

## Observação conhecida

`verify_composite.gd` pode estar inconsistente com o retorno em **dicionário** do `CompositeResolver` (tratar como lista indexada). Corrigir quando for mexer nessa área.
