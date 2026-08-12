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

## Como marcar os ímãs

No Godot, abra o arquivo `.tres` da peça (ex.: `data/parts/vampiro_head.tres`).

No Inspetor você verá:

| Campo | Quem usa | Significado |
|-------|----------|-------------|
| `magnet_up` | Corpo e Pernas | Ponto que gruda na peça **acima** |
| `magnet_down` | Cabeça e Corpo | Ponto que gruda na peça **abaixo** |

### Sistema de coordenadas (simples)

- Medido em **pixels da textura**, a partir do **centro** da imagem
- **Y negativo** = para cima na imagem  
- **Y positivo** = para baixo na imagem  
- **X** move esquerda/direita (0 = meio)

Exemplos (arte 300×300):

- Cabeça: `magnet_down = (0, 120)` → perto da base do pescoço  
- Corpo: `magnet_up = (0, -120)` e `magnet_down = (0, 120)`  
- Pernas: `magnet_up = (0, -120)` → perto da cintura  

### Regra de colagem

1. O tronco fica no centro da carta  
2. Cabeça: `ímã de baixo da cabeça` cola no `ímã de cima do tronco`  
3. Pernas: `ímã de cima das pernas` cola no `ímã de baixo do tronco`  

Ajuste os números até as partes “grudarem” visualmente no lugar certo.

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
