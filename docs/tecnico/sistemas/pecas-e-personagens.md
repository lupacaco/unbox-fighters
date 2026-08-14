# Sistema: peças e personagens

Como o jogo descreve personagens e decide o que desenhar na carta.

## Tipos de dados

### `PartSlotType` (`scripts/data/part_slot_type.gd`)

Seis encaixes: `HEAD`, `BODY`, `ARM_L`, `ARM_R`, `LEG_L`, `LEG_R`.

Esquerda/direita = lado **de quem olha** o desenho de frente.

### `PartDef` (`scripts/data/part_def.gd`)

Recurso de **uma peça**:

- `id`, `display_name`
- `slot_type` (um dos 6 encaixes)
- `set_id` (hoje o teste usa `leao`)
- `sprite` — frente (pose 1)
- `sprite_profile` — perfil (pose 2). Precisa existir para a luta.
- `sprite_attack` — golpe (opcional; se faltar, a luta usa o perfil)
- `combat_value` — número da peça
- `tier` — nível da loja em que a peça pode aparecer
- **Ímãs** (pontos de união, em pixels a partir do centro da imagem 200×200):
  - Cabeça: `magnet_down` (esfera na base do pescoço)
  - Braço / perna: `magnet_up` (esfera no topo)
  - Tronco: **5 ímãs** — `magnet_neck`, `magnet_shoulder_l`, `magnet_shoulder_r`, `magnet_hip_l`, `magnet_hip_r`
  - Frente e perfil podem ser diferentes (`magnet_*_profile`)

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- Referências `head`, `body`, `arm_l`, `arm_r`, `leg_l`, `leg_r`

## Números atuais (teste)

Só o **Leão** está na loja. As outras fichas (vampiro, policial, etc.) continuam na pasta, mas a loja as ignora (`ShopPool.ACTIVE_SET_IDS = ["leao"]`).

| Set | Cada peça | Total do set completo |
|-----|-----------|------------------------|
| Leão | 4 (nível 1) | 24 |

A sinergia (6 iguais = 100%, 3–5 = 75%, 1–2 = 50%) está em `scripts/match/synergy.gd`.

A loja lê sozinha as fichas `*_character.tres` em `data/parts/`, e depois filtra pelos ids ativos.

## Como marcar os ímãs

1. No Godot, menu **Project → Tools → Ímãs das Peças** (em português: **Projeto → Ferramentas**).
2. Clique na peça em `data/parts/`, ex.: `leao_body.tres`.
3. Escolha **Frente** ou **De lado**.
4. Arraste as bolinhas até o **centro das esferas de metal**:
   - Cabeça: **BAIXO**
   - Braço / perna: **CIMA**
   - Tronco: **PESCOÇO**, **OMBRO E**, **OMBRO D**, **QUADRIL E**, **QUADRIL D**
5. Salve (`Ctrl+S`).

A mesma ferramenta aparece no Inspetor, com o botão **Abrir ferramenta de ímãs (imagem grande)**. Na janela grande dá para misturar as 6 peças e ver se os encaixes batem.

Marque **frente e perfil**. A carta usa a frente; a luta usa o perfil.

### Sistema de coordenadas

- Medido em **pixels da textura**, a partir do **centro** da imagem 200×200
- **Y negativo** = para cima
- **Y positivo** = para baixo

### Regra de colagem

1. O tronco fica no centro da carta
2. Cabeça: esfera de baixo cola na esfera do pescoço do tronco
3. Braços: esfera de cima cola nos ombros
4. Pernas: esfera de cima cola nos quadris

## Arte relacionada

Padrão de arquivos em `assets/characters/<nome>/`:

- `<nome>_head-1.png` / `_body-1` / `_arm_l-1` / `_arm_r-1` / `_leg_l-1` / `_leg_r-1` — frente
- Os mesmos com `-2` — perfil

Todos em **200×200**. No jogo o tamanho fica 1:1 (não estica).

Para colocar um Freak **novo**, veja [Incluir personagem](../incluir-personagem.md).

## Arquivos de dados atuais

Pasta: `data/parts/`

| Arquivo | Conteúdo |
|---------|----------|
| `leao_character.tres` + `leao_*.tres` | Leão (único set ativo na loja) |
| `vampiro_*`, `policial_*`, `bruxa_*`, `mumia_*`, `medico_*`, `cachorro_*` | Sets antigos de 3 peças — desligados da loja |
