# Sistema: peças e personagens

Como o jogo descreve personagens e decide o que desenhar na carta.

## O que o jogador vê vs o desenho

Na **loja** existem **2 kits**:

- **Cabeça**
- **Corpo** (o peito dentro do caixote, já com os dois braços)

Na **carta** e na **esteira** o corpo mostra **três desenhos** (tronco, braço E e braço D), para cada braço poder se mexer. Na esteira, a cabeça leva a etiqueta de **Ataque** e o tronco a de **HP**.

O **caixote** (`assets/nova-ui/caixote.png`) é a **base fixa** de todos os Freaks. Não é um kit da loja. Fica nas cartas (mesmo vazias) e na esteira. O tronco tem um ímã embaixo que encaixa no caixote; a frente do caixote tapa a parte de baixo do tronco, como se o Freak estivesse sentado dentro.

- Cabeça cola no pescoço do tronco
- Cada braço cola no ombro
- Tronco cola no caixote pelo ímã de baixo
- Sem tronco: a cabeça e os braços ficam soltos acima do caixote

## Tipos de dados

### `PartSlotType` (`scripts/data/part_slot_type.gd`)

- Loja: `HEAD`, `BODY`
- Desenho: `HEAD`, `BODY`, `ARM_L`, `ARM_R`

Esquerda/direita no desenho = lado **de quem olha** a frente.

### `PartStats` (`scripts/data/part_stats.gd`)

O que o número de um kit significa, e quanto custa:

- Cabeça = Ataque (1 a 10) → preço = Ataque
- Corpo = HP (10 a 20) → preço = HP − 10 (mínimo $1)
- Vender = metade do pago, arredondado para cima

### `PartDef` (`scripts/data/part_def.gd`)

Recurso de **uma peça** (kit da loja ou recorte de desenho):

- `id`, `display_name`
- `slot_type`
- `set_id`
- `sprite` — frente (pose 1)
- `sprite_profile` — perfil (pose 2). Precisa existir nos desenhos visíveis para a luta
- `stat_value` — Ataque ou HP, conforme o encaixe
- `tier` — faixa do número (a loja atual não trava por nível)
- `kit_parts` — só no agrupamento antigo `ARMS` (não é vendido)
- **Ímãs** (pontos de união, em pixels a partir do centro da imagem 200×200):
  - Cabeça: `magnet_down` (esfera na base do pescoço)
  - Braço: `magnet_up` (esfera no topo)
  - Tronco: **4 ímãs** — `magnet_neck`, `magnet_shoulder_l`, `magnet_shoulder_r`, `magnet_ground` (esfera de baixo, encaixa no caixote)
  - Frente e perfil podem ser diferentes (`magnet_*_profile`)

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- `kind` — Humano, Sobrenatural ou Animal
- `ability` — Poder do set completo (Controle de Mente, Recurso, ou nenhum)
- Desenho: `head`, `body`, `arm_l`, `arm_r`
- Loja: `head`, `body`

A loja lê `shop_parts()` (2 kits).

## Números atuais

Na loja entram **todos** os Freaks que tiverem ficha `*_character.tres`. Hoje:

| Set | Tipo | Ataque | HP | Custo | Poder |
|-----|------|--------|----|-------|-------|
| Bruxa | Sobrenatural | 8 | 15 | $13 | Controle de Mente |
| Advogado | Humano | 4 | 18 | $12 | Recurso |

Duas peças do **mesmo tipo** dão +50% em Ataque e HP (`scripts/match/synergy.gd`). O Poder só liga se cabeça e corpo forem do **mesmo** Freak.

A loja lê sozinha as fichas `*_character.tres` em `data/parts/` e vende os 2 kits de cada uma.

## Como marcar os ímãs

1. No Godot, menu **Project → Tools → Ímãs das Peças** (em português: **Projeto → Ferramentas**).
2. No alto, escolha o **Freak**. A janela tem duas abas: **Frente** e **Perfil**.
3. À esquerda, as **4 partes em duas colunas**. À direita, a prévia do Freak montado.
4. Arraste as bolinhas até o **centro das esferas de metal**:
   - Cabeça: **BAIXO**
   - Braço: **CIMA**
   - Tronco: **PESCOÇO**, **OE**, **OD**, **CAIXOTE** (esfera de baixo do tronco)
5. Clique **Salvar**.

Marque **frente e perfil**. A carta usa a frente; a esteira usa o perfil.

### Sistema de coordenadas

- Medido em **pixels da textura**, a partir do **centro** da imagem 200×200
- **Y negativo** = para cima
- **Y positivo** = para baixo

### Regra de colagem

1. A base do caixote senta no chão da carta ou nos rolos da esteira.
2. O tronco encaixa no caixote pelo ímã de baixo.
3. A cabeça cola no pescoço.
4. Braços: esfera de cima cola nos ombros. Na **frente**, os braços abrem um pouco, girando nesse ímã (não soltam). Na carta, os braços ficam **na frente** do caixote. Na esteira, a cabeça fica **na frente** do tronco.

## Arte relacionada

Padrão de arquivos em `assets/characters/<nome>/`:

- `<nome>_head-1.png` / `_body-1` / `_arm_l-1` / `_arm_r-1` — frente
- Os mesmos com `-2` — perfil

Todos em **200×200**. No jogo o tamanho fica 1:1 (não estica).

Para colocar um Freak **novo**, veja [Incluir personagem](../incluir-personagem.md). Para tirar um Freak de vez: **Project → Tools → Remover personagem**.

## Arquivos de dados atuais

Pasta: `data/parts/`

| Arquivo | Conteúdo |
|---------|----------|
| `bruxa_character.tres` + `bruxa_head/body/arms/arm_*.tres` | Kits da loja (Bruxa) |
| `advogado_character.tres` + `advogado_head/body/arms/arm_*.tres` | Kits da loja (Advogado) |
