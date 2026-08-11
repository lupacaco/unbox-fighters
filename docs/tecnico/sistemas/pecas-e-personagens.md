# Sistema: peças e personagens

Como o jogo descreve personagens e decide o que desenhar na carta.

## Tipos de dados

### `PartSlotType` (`scripts/data/part_slot_type.gd`)

Enum: `HEAD`, `BODY`, `LEGS`.

### `PartDef` (`scripts/data/part_def.gd`)

Recurso de **uma peça**:

- `id`, `display_name`
- `slot_type` (cabeça / tronco / pernas)
- `sprite`
- `brain`, `power`, `speed`

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- Referências `head`, `body`, `legs` (`PartDef`)
- Sprites compostos opcionais:
  - `body_head_sprite` — tronco + cabeça
  - `body_legs_sprite` — tronco + pernas
  - `full_sprite` — personagem completo

## Arquivos de dados atuais

Pasta: `data/parts/`

| Arquivo | Conteúdo |
|---------|----------|
| `vampiro_character.tres` | Personagem vampiro + links das peças e compostos |
| `vampiro_head.tres` | Cabeça — BRN 8 / PWR 2 / SPD 3 |
| `vampiro_body.tres` | Tronco — BRN 1 / PWR 9 / SPD 2 |
| `vampiro_legs.tres` | Pernas — BRN 0 / PWR 3 / SPD 8 |

## Composição visual (`CompositeResolver`)

Arquivo: `scripts/data/composite_resolver.gd`

Recebe o personagem e quais slots estão preenchidos. Devolve um plano:

| Situação | Modo |
|----------|------|
| Cabeça + tronco + pernas e existe `full_sprite` | `composite` (imagem completa) |
| Cabeça + tronco (sem pernas) e existe `body_head_sprite` | `composite` |
| Tronco + pernas (sem cabeça) e existe `body_legs_sprite` | `composite` |
| Qualquer outra combinação válida | `layered` (desenha as partes separadas nas âncoras) |
| Nada / personagem nulo | `empty` |

Isso deixa o visual mais bonito quando há arte pré-montada, sem perder a montagem peça a peça.

## Arte relacionada

Sprites em `assets/characters/vampiro/` (partes e compostos; também existem versões `.webp` e arquivos `_src_*` de origem).

Tamanho esperado das partes normalizadas: **300×300** (ver pipeline de arte e testes).
