# Sistema: peças e personagens

Como o jogo descreve personagens e decide o que desenhar na carta.

## Tipos de dados

### `PartSlotType` (`scripts/data/part_slot_type.gd`)

Enum: `HEAD`, `BODY`, `LEGS`.

### `PartDef` (`scripts/data/part_def.gd`)

Recurso de **uma peça** (script com `@tool` para o editor poder ler/validar ímãs no Inspetor):

- `id`, `display_name`
- `slot_type` (cabeça / tronco / pernas)
- `set_id` (vampiro, policial, bruxa, mumia, medico, cachorro) — usado na sinergia
- `sprite` — frente (pose 1)
- `sprite_profile` — perfil (pose 2)
- `sprite_attack` — ataque (pose 3)
- `combat_value` — um número só (Ameaça / Força / Agilidade conforme o tipo)
- `tier` — nível da loja em que a peça pode aparecer
- **Ímãs** (pontos de união):
  - `magnet_up` — cola na peça de cima
  - `magnet_down` — cola na peça de baixo

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- Referências `head`, `body`, `legs` (`PartDef`)

## Números atuais

- Policial: 7 / 6 / 5
- Vampiro: 9 / 9 / 8
- Bruxa: 9 / 4 / 9
- Múmia: 5 / 8 / 6
- Médico: 3 / 4 / 4
- Cachorro: 5 / 5 / 7

A sinergia (100 / 75 / 50) está em `scripts/match/synergy.gd`.

## Como marcar os ímãs (ponto exato)

1. No Godot, ative o plugin **Part Magnet Editor** (já vem no projeto).
2. Abra a peça, ex.: `data/parts/vampiro_body.tres`.
3. No Inspetor, em cima, aparece a **imagem da peça**.
4. Clique em **Marcar Ímã de Cima** ou **Marcar Ímã de Baixo**.
5. Clique no ponto exato da imagem (ex.: o círculo do pescoço / cintura).
6. Salve o recurso (`Ctrl+S`).

Marcadores:
- **CIMA** (azul) = `magnet_up` — aparece em tronco e pernas
- **BAIXO** (vermelho) = `magnet_down` — aparece em cabeça e tronco

Regras por tipo:
- **Cabeça** → só ímã de baixo
- **Pernas** → só ímã de cima
- **Tronco** → os dois

### Sistema de coordenadas (se precisar editar o número)

- Medido em **pixels da textura**, a partir do **centro** da imagem
- **Y negativo** = para cima  
- **Y positivo** = para baixo  

### Regra de colagem

1. O tronco fica no centro da carta  
2. Cabeça: `magnet_down` cola no `magnet_up` do tronco  
3. Pernas: `magnet_up` cola no `magnet_down` do tronco  

## Arte relacionada

Padrão de arquivos por personagem em `assets/characters/<nome>/`:

- `<nome>_head-1.png` / `_body-1` / `_legs-1` — frente
- `<nome>_head-2.png` / `_body-2` / `_legs-2` — perfil
- `<nome>_head-3.png` / `_body-3` / `_legs-3` — ataque

Todos em **300×200**. No jogo todas crescem iguais (ficam com 250 px de largura).

## Arquivos de dados atuais

Pasta: `data/parts/`

| Arquivo | Conteúdo |
|---------|----------|
| `vampiro_character.tres` + `vampiro_*.tres` | Vampiro |
| `policial_character.tres` + `policial_*.tres` | Policial |
| `bruxa_character.tres` + `bruxa_*.tres` | Bruxa |
| `mumia_character.tres` + `mumia_*.tres` | Múmia |
| `medico_character.tres` + `medico_*.tres` | Médico |
| `cachorro_character.tres` + `cachorro_*.tres` | Cachorro |
