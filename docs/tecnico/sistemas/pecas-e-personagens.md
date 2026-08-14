# Sistema: peças e personagens

Como o jogo descreve personagens e decide o que desenhar na carta.

## O que o jogador vê vs o desenho

Na **loja** e na **carta** existem 3 kits:

- **Cabeça**
- **Tronco** = tronco + os dois braços (já vêm juntos)
- **Pernas** = as duas pernas juntas

O **desenho** ainda tem 6 recortes 200×200, para o Freak andar e atacar mexendo braços e pernas. `PartKit` (`scripts/data/part_kit.gd`) transforma o kit da loja nesses 6 desenhos.

## Tipos de dados

### `PartSlotType` (`scripts/data/part_slot_type.gd`)

- Loja / luta: `HEAD`, `BODY`, `LEGS`
- Desenho: `HEAD`, `BODY`, `ARM_L`, `ARM_R`, `LEG_L`, `LEG_R`

Esquerda/direita no desenho = lado **de quem olha** a frente.

### `PartDef` (`scripts/data/part_def.gd`)

Recurso de **uma peça** (kit da loja ou recorte de desenho):

- `id`, `display_name`
- `slot_type`
- `set_id` (hoje o teste usa `leao`)
- `sprite` — frente (pose 1). O kit de pernas da loja **não** tem PNG próprio.
- `sprite_profile` — perfil (pose 2). Precisa existir nos 6 desenhos para a luta.
- `combat_value` — número do kit na loja
- `tier` — nível da loja em que o kit pode aparecer
- **Ímãs** (pontos de união, em pixels a partir do centro da imagem 200×200):
  - Cabeça: `magnet_down` (esfera na base do pescoço)
  - Braço / perna: `magnet_up` (esfera no topo)
  - Tronco: **5 ímãs** — `magnet_neck`, `magnet_shoulder_l`, `magnet_shoulder_r`, `magnet_hip_l`, `magnet_hip_r`
  - Frente e perfil podem ser diferentes (`magnet_*_profile`)

A luta **não** usa pose de golpe. O ataque mexe os membros no palco.

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- Desenho: `head`, `body`, `arm_l`, `arm_r`, `leg_l`, `leg_r`
- Loja: `head`, `body`, `legs` (kit das duas pernas)

A loja lê `shop_parts()` (3 kits). Braços e pernas soltos **não** entram nas caixas.

## Números atuais (teste)

Só o **Leão** está na loja. As outras fichas (vampiro, policial, etc.) continuam na pasta, mas a loja as ignora (`ShopPool.ACTIVE_SET_IDS = ["leao"]`).

| Set | Cada kit | Total do set completo |
|-----|----------|------------------------|
| Leão | 4 (nível 1) | 12 |

A sinergia (3 iguais = 100%, 2 = 75%, 1 = 50%) está em `scripts/match/synergy.gd`.

A loja lê sozinha as fichas `*_character.tres` em `data/parts/`, e depois filtra pelos ids ativos.

## Como marcar os ímãs

1. No Godot, menu **Project → Tools → Ímãs das Peças** (em português: **Projeto → Ferramentas**).
2. No alto, escolha o **Freak**. A janela mostra as **12 partes** (frente em cima, de lado embaixo).
3. Arraste as bolinhas até o **centro das esferas de metal**:
   - Cabeça: **BAIXO**
   - Braço / perna: **CIMA**
   - Tronco: **PESCOÇO**, **OE**, **OD**, **QE**, **QD**
4. Olhe a prévia embaixo (Freak montado). Clique **Salvar ímãs**.

Não use o kit `*_legs.tres` (não tem desenho). A ferramenta lê as 6 imagens de desenho × 2 poses.

Marque **frente e perfil**. A carta usa a frente; a luta usa o perfil.

Se uma peça estiver aberta no Inspetor, o botão **Abrir as 12 partes deste Freak** abre a mesma tela já nesse Freak.

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
| `leao_character.tres` + `leao_head/body/legs.tres` | Kits da loja (Leão) |
| `leao_arm_*.tres`, `leao_leg_l/r.tres` | Só desenho (não vendidos) |
| `vampiro_*`, `policial_*`, `bruxa_*`, `mumia_*`, `medico_*`, `cachorro_*` | Sets antigos de 3 PNGs — desligados da loja |
