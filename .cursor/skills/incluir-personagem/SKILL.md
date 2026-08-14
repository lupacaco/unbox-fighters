---
name: incluir-personagem
description: Adds a new Unbox Fighters character set from a 6+6 sprite sheet (PNG/WEBP). Use when the user provides character art, asks to include a personagem, novo set, folha de partes, or a path under assets/characters.
---

# Incluir personagem

Antes de cortar ou ligar qualquer coisa, leia `docs/tecnico/incluir-personagem.md` e siga **todos** os passos.

## Não faça

- Não apague todo pixel preto da folha. Só o preto ligado às **bordas**.
- Não deixe de marcar os ímãs na ferramenta **Project → Tools → Ímãs das Peças** (frente e perfil). Não chute X = 0.
- Não invente outro fluxo (não recrie a cena, não liste o personagem na mão — a loja lê `data/parts/*_character.tres`).

## Faça nesta ordem

1. Cortar a folha em 12 PNG **200×200** transparentes em `assets/characters/{id}/` (`{id}_head-1.png` … `_leg_r-2.png`). Frente `-1`, lado `-2`.
   - Comando: `python tools/slice_character_sheet.py CAMINHO_DA_FOLHA --id ID --name NOME --value 4 --write-defs`
   - Ou no Godot: **Project → Tools → Incluir personagem** (3 números da loja: cabeça, tronco, pernas)
2. Medir ímãs com **Project → Tools → Ímãs das Peças**: arraste cada bolinha até a esfera de metal. No tronco são 5 (pescoço, ombros, quadris). Marque os **6 desenhos**, não o kit `*_legs.tres`.
3. Números: os 3 da loja que o jogador pediu; senão um conjunto diferente dos sets atuais. `tier` pela tabela da loja (3–5 → nível 1; 9 → nível 5).
4. Conferir `data/parts/{id}_*.tres` e `{id}_character.tres` (loja = head/body/legs). A loja pega o set sozinha (ou via `ACTIVE_SET_IDS` se houver filtro de teste).
5. Atualizar `pecas-e-personagens.md`, `estado-atual.md`, `estrutura-de-pastas.md`.
