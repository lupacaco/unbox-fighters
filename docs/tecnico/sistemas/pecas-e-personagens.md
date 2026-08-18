# Sistema: peças e personagens

Como o jogo descreve personagens e decide o que desenhar na carta.

## O que o jogador vê vs o desenho

Na **loja** existem **3 kits**:

- **Cabeça**
- **Tronco** (o peito dentro do caixote)
- **Braços** (os dois juntos numa caixa)

Na **carta** e na **esteira** o kit de braços vira **dois desenhos** (braço E e braço D), para cada braço poder se mexer.

O chão do Freak é a **base do caixote**. Não tem pernas e não tem mola.

- Cabeça cola no pescoço do tronco
- Cada braço cola no ombro
- Sem tronco: a cabeça e os braços ficam soltos acima da prateleira da carta

## Tipos de dados

### `PartSlotType` (`scripts/data/part_slot_type.gd`)

- Loja: `HEAD`, `BODY`, `ARMS`
- Desenho: `HEAD`, `BODY`, `ARM_L`, `ARM_R`

Esquerda/direita no desenho = lado **de quem olha** a frente.

### `PartStats` (`scripts/data/part_stats.gd`)

O que o número de um kit significa, e quanto custa:

- Cabeça = Poder (1 a 10) → preço = Poder
- Tronco = Resistência (10 a 20) → preço = Resistência − 10 (mínimo $1)
- Braços = Agilidade (1 a 5) → preço = Agilidade
- Vender = metade do pago, arredondado para cima

### `PartDef` (`scripts/data/part_def.gd`)

Recurso de **uma peça** (kit da loja ou recorte de desenho):

- `id`, `display_name`
- `slot_type`
- `set_id`
- `sprite` — frente (pose 1)
- `sprite_profile` — perfil (pose 2). Precisa existir nos desenhos visíveis para a luta
- `stat_value` — Poder, Resistência ou Agilidade, conforme o encaixe
- `tier` — faixa do número (a loja atual não trava por nível)
- `kit_parts` — no kit `ARMS`, aponta para `arm_l` e `arm_r`
- **Ímãs** (pontos de união, em pixels a partir do centro da imagem 200×200):
  - Cabeça: `magnet_down` (esfera na base do pescoço)
  - Braço: `magnet_up` (esfera no topo)
  - Tronco: **4 ímãs** — `magnet_neck`, `magnet_shoulder_l`, `magnet_shoulder_r`, `magnet_ground`
  - Frente e perfil podem ser diferentes (`magnet_*_profile`)

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- Desenho: `head`, `body`, `arm_l`, `arm_r`
- Loja: `head`, `body`, `arms`

A loja lê `shop_parts()` (3 kits).

## Números atuais

Na loja entram **todos** os Freaks que tiverem ficha `*_character.tres`. Hoje:

| Set | Poder | Resistência | Agilidade | Custo |
|-----|-------|-------------|-----------|-------|
| Bruxa | 8 | 15 | 2 | $15 |
| Advogado | 4 | 18 | 5 | $17 |

A sinergia (dupla +25%, tripla +50%) está em `scripts/match/synergy.gd`.

A loja lê sozinha as fichas `*_character.tres` em `data/parts/` e vende os 3 kits de cada uma.

## Como marcar os ímãs

1. No Godot, menu **Project → Tools → Ímãs das Peças** (em português: **Projeto → Ferramentas**).
2. No alto, escolha o **Freak**. A janela tem duas abas: **Frente** e **Perfil**.
3. À esquerda, as **4 partes em duas colunas**. À direita, a prévia do Freak montado.
4. Arraste as bolinhas até o **centro das esferas de metal**:
   - Cabeça: **BAIXO**
   - Braço: **CIMA**
   - Tronco: **PESCOÇO**, **OE**, **OD**, **CHÃO** (base do caixote)
5. Clique **Salvar**.

Marque **frente e perfil**. A carta usa a frente; a esteira usa o perfil.

### Sistema de coordenadas

- Medido em **pixels da textura**, a partir do **centro** da imagem 200×200
- **Y negativo** = para cima
- **Y positivo** = para baixo

### Regra de colagem

1. A base do caixote senta no chão da carta ou nos rolos da esteira.
2. A cabeça cola no pescoço.
3. Braços: esfera de cima cola nos ombros. Na **frente**, os braços abrem um pouco, girando nesse ímã (não soltam).

## Arte relacionada

Padrão de arquivos em `assets/characters/<nome>/`:

- `<nome>_head-1.png` / `_body-1` / `_arm_l-1` / `_arm_r-1` — frente
- Os mesmos com `-2` — perfil

Todos em **200×200**. No jogo o tamanho fica 1:1 (não estica).

Para colocar um Freak **novo**, veja [Incluir personagem](../incluir-personagem.md).

## Arquivos de dados atuais

Pasta: `data/parts/`

| Arquivo | Conteúdo |
|---------|----------|
| `bruxa_character.tres` + `bruxa_head/body/arms/arm_*.tres` | Kits da loja (Bruxa) |
| `advogado_character.tres` + `advogado_head/body/arms/arm_*.tres` | Kits da loja (Advogado) |
