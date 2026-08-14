---
name: incluir-personagem
description: Adds a new Unbox Fighters character set from a 3x3 sprite sheet (PNG/WEBP). Use when the user provides character art, asks to include a personagem, novo set, folha 3x3, or a path under assets/characters.
---

# Incluir personagem

Antes de cortar ou ligar qualquer coisa, leia `docs/tecnico/incluir-personagem.md` e siga **todos** os passos.

## Não faça

- Não apague todo pixel preto da folha. Só o preto ligado às **bordas** (mancha de dálmata, estetoscópio e olho ficam).
- Não deixe de marcar os ímãs na ferramenta **Project → Tools → Ímãs das Peças** (frente, lado e golpe). Não chute X = 0.
- Não invente outro fluxo (não recrie a cena, não liste o personagem na mão — a loja lê `data/parts/*_character.tres`).

## Faça nesta ordem

1. Cortar a grade 3×3 em 9 PNG **300×200** transparentes em `assets/characters/{id}/` (`{id}_head-1.png` … `_legs-3.png`). Frente `-1`, lado `-2`, golpe `-3`.
   - Comando: `python tools/slice_character_sheet.py CAMINHO_DA_FOLHA --id ID --name NOME --head N --body N --legs N --write-defs`
   - Ou no Godot: **Project → Tools → Incluir personagem**
2. Medir ímãs com **Project → Tools → Ímãs das Peças**: arraste CIMA/BAIXO até o pescoço/cintura, e no tronco a bolinha dourada ARMA até a mão, na frente, de lado e no golpe.
3. Números: os que o jogador pediu; senão um conjunto diferente dos sets atuais. `tier` pela tabela da loja (3–5 → nível 1; 9 → nível 5).
4. Conferir `data/parts/{id}_*.tres` e `{id}_character.tres`. A loja pega o set sozinha.
5. Atualizar `pecas-e-personagens.md`, `estado-atual.md`, `estrutura-de-pastas.md`.
