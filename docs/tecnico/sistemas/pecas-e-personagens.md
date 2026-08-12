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
- **Ímãs** (pontos de união):
  - `magnet_up` — cola na peça de cima
  - `magnet_down` — cola na peça de baixo

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- Referências `head`, `body`, `legs` (`PartDef`)

Não usa mais imagens pré-montadas (full / body_head / body_legs). Só as 3 partes.

## Como marcar os ímãs (ponto exato)

1. No Godot, ative o plugin **Part Magnet Editor** (já vem no projeto).
2. Abra a peça, ex.: `data/parts/vampiro_body.tres`.
3. No Inspetor, em cima, aparece a **imagem da peça**.
4. Clique em **Marcar Ímã de Cima** ou **Marcar Ímã de Baixo**.
5. Clique no ponto exato da imagem (ex.: o círculo do pescoço / cintura).
6. Salve o recurso (`Ctrl+S`).

Marcadores:
- **CIMA** (azul) = `magnet_up`
- **BAIXO** (vermelho) = `magnet_down`

### Sistema de coordenadas (se precisar editar o número)

- Medido em **pixels da textura**, a partir do **centro** da imagem
- **Y negativo** = para cima  
- **Y positivo** = para baixo  

### Regra de colagem

1. O tronco fica no centro da carta  
2. Cabeça: `magnet_down` cola no `magnet_up` do tronco  
3. Pernas: `magnet_up` cola no `magnet_down` do tronco  

## Arquivos de dados atuais

Pasta: `data/parts/`

| Arquivo | Conteúdo |
|---------|----------|
| `vampiro_character.tres` | Personagem vampiro + links das peças |
| `vampiro_head.tres` | Cabeça + `magnet_down` |
| `vampiro_body.tres` | Tronco + `magnet_up` / `magnet_down` |
| `vampiro_legs.tres` | Pernas + `magnet_up` |

## Composição visual (`CompositeResolver`)

Arquivo: `scripts/data/composite_resolver.gd`

Sempre no modo **layered** (só partes). Calcula a posição de cada sprite pelos ímãs.

## Arte relacionada

Sprites em `assets/characters/vampiro/` — use `head`, `body`, `legs` (300×300).  
Imagens `full` / `body_head` / `body_legs` podem existir na pasta, mas **não são mais usadas** pelo jogo.
