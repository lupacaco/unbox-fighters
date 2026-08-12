# Pernas 3D com passos (preview)

Cena de teste para ver as **pernas do policial em 3D dando passos**.  
**Não** é a tela principal do jogo. A montagem continua em 2D.

## Como ver

1. Abra o projeto no Godot 4.7
2. Abra a cena `scenes/preview/LegsWalkPreview.tscn`
3. Aperte F6 (roda só essa cena)

A câmera gira devagar em volta das pernas. Elas ficam no lugar, como numa esteira, para ficar fácil de olhar.

## O que o arquivo original tinha

O `.glb` que você passou era só o **modelo parado**: a forma 3D e a textura (a “pele” pintada).  
Não tinha **esqueleto** (ossos internos) nem animação.

Sem ossos, o computador não consegue dobrar joelho e quadril de verdade. Só conseguiria girar o bloco inteiro, o que não parece um passo.

## O que foi feito

1. Copiamos o modelo para `assets/characters/policial/3d/policial-legs-3d.glb`
2. Um script criou ossos (quadril, coxa, canela, pé — esquerda e direita) e “pregou” a malha nesses ossos. Malha é a superfície 3D, feita de triângulos.
3. Gravamos uma animação `walk` que alterna os pés, dobra os joelhos e sobe o pé no ar.
4. A cena de preview toca essa animação em loop.

Arquivo já animado: `assets/characters/policial/3d/policial-legs-3d-walk.glb`

## Limite importante

O modelo original não foi feito para animar (não veio com ossos de um programa de modelagem).  
O passo funciona, mas o tecido pode esticar um pouco no joelho e na virilha. Isso é esperado neste tipo de modelo.

Para um passo de qualidade de filme, o ideal é um artista criar os ossos no Blender (programa de modelagem 3D).

## Como gerar de novo

Na pasta do projeto:

```
python tools/rig_legs_walk.py
```

Isso lê `policial-legs-3d.glb` e reescreve `policial-legs-3d-walk.glb`.

## Arquivos

| Arquivo | Função |
|---------|--------|
| `tools/rig_legs_walk.py` | Cria ossos + animação de passo |
| `assets/characters/policial/3d/policial-legs-3d.glb` | Modelo original, parado |
| `assets/characters/policial/3d/policial-legs-3d-walk.glb` | Modelo com ossos e passos |
| `scenes/preview/LegsWalkPreview.tscn` | Cena para assistir |
| `scripts/preview/legs_walk_preview.gd` | Sobe a cena, luz, chão e toca `walk` |
| `scripts/core/verify_legs_walk.gd` | Confere se os ossos e a animação existem |
