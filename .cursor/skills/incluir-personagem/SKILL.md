---
name: incluir-personagem
description: Adds a new Unbox Fighters character set from a 4+4 sprite sheet (PNG/WEBP). Use when the user provides character art, asks to include a personagem, novo set, folha de partes, or a path under assets/characters.
---

# Incluir personagem

Antes de cortar ou ligar qualquer coisa, leia `docs/tecnico/incluir-personagem.md` e siga **todos** os passos.

## Não faça

- Não apague todo pixel preto da folha. Só o preto ligado às **bordas**.
- Não deixe de marcar os ímãs na ferramenta **Project → Tools → Ímãs das Peças** (abas Frente e Perfil). Não chute X = 0.
- Não invente outro fluxo (não recrie a cena, não liste o personagem na mão — a loja lê `data/parts/*_character.tres`).

## Faça nesta ordem

1. Cortar a folha em 8 PNG **200×200** transparentes em `assets/characters/{id}/` (`{id}_head-1.png` … `_arm_r-2.png`). Frente `-1`, lado `-2`.
   - Comando: `python tools/slice_character_sheet.py CAMINHO_DA_FOLHA --id ID --name NOME --attack 8 --hp 15 --kind supernatural --overlay`
   - Depois: `godot --headless --path . --script scripts/core/import_roster.gd`
   - Ou no Godot: **Project → Tools → Incluir personagem** (Ataque, HP, tipo e Poder)
2. Medir ímãs com **Project → Tools → Ímãs das Peças**: abas **Frente** e **Perfil**, 4 partes à esquerda, prévia à direita. Arraste cada bolinha até a esfera de metal. No tronco são 4 (pescoço, ombros, e CAIXOTE embaixo).
3. Números: os 2 que o jogador pediu; senão um conjunto diferente dos sets atuais. Cabeça = Ataque 1–10, corpo = HP 10–20. Tipo: Humano, Sobrenatural ou Animal. Poder só no set completo.
4. Conferir `data/parts/{id}_*.tres` e `{id}_character.tres` (loja = head/body). A loja lê sozinha todo `*_character.tres`.
5. Atualizar `pecas-e-personagens.md`, `estado-atual.md`, `estrutura-de-pastas.md`.
