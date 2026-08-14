# Sistema: peças e personagens

Como o jogo descreve personagens e decide o que desenhar na carta.

## O que o jogador vê vs o desenho

Na **loja** e na **carta** existem **4 kits**:

- **Cabeça**
- **Tronco** (só o peito; os braços não vêm grudados)
- **Braço E** (esquerda de quem olha)
- **Braço D** (direita de quem olha)

Toda carta já tem uma **base-mola** (`scripts/data/spring_base.gd`). Não vem na caixa, não tem número, não dá para remover.

- Vazia: mola solta (`assets/objects/base-mola-solta.png`)
- Com qualquer peça: mola pressionada (`assets/objects/base-mola-pressionada.png`)
- Só a cabeça: a esfera de baixo da cabeça cola na esfera da mola
- Cabeça + tronco: o meio dos quadris do tronco cola nessa esfera; a cabeça cola no pescoço
- Braço com tronco: a esfera de cima do braço cola no ombro
- Braço sem tronco: o braço senta na esfera da mola, um pouco para o lado

Os arquivos de perna continuam no set para a ferramenta de ímãs, mas **não são desenhados nem vendidos**.

## Tipos de dados

### `PartSlotType` (`scripts/data/part_slot_type.gd`)

- Loja / luta: `HEAD`, `BODY`, `ARM_L`, `ARM_R`
- Desenho: os mesmos, mais `LEG_L` / `LEG_R` só nos arquivos (ocultos no jogo)

Esquerda/direita no desenho = lado **de quem olha** a frente.

### `PartDef` (`scripts/data/part_def.gd`)

Recurso de **uma peça** (kit da loja ou recorte de desenho):

- `id`, `display_name`
- `slot_type`
- `set_id`
- `sprite` — frente (pose 1)
- `sprite_profile` — perfil (pose 2). Precisa existir nos desenhos visíveis para a luta
- `combat_value` — número do kit na loja
- `tier` — nível da loja em que o kit pode aparecer
- **Ímãs** (pontos de união, em pixels a partir do centro da imagem 200×200):
  - Cabeça: `magnet_down` (esfera na base do pescoço)
  - Braço: `magnet_up` (esfera no topo)
  - Tronco: **5 ímãs** — `magnet_neck`, `magnet_shoulder_l`, `magnet_shoulder_r`, `magnet_hip_l`, `magnet_hip_r`
  - Frente e perfil podem ser diferentes (`magnet_*_profile`)

A luta **não** usa pose de golpe. Só o kit que ganha o choque sai do corpo e voa até a peça do adversário.

### `CharacterDef` (`scripts/data/character_def.gd`)

Recurso de **um personagem**:

- `id`, `display_name`
- Desenho: `head`, `body`, `arm_l`, `arm_r` (e `leg_l` / `leg_r` nos arquivos)
- Loja: `head`, `body`, `arm_l`, `arm_r`

A loja lê `shop_parts()` (4 kits). Pernas **não** entram nas caixas.

## Números atuais (teste)

Na loja entram **todos** os Freaks que tiverem ficha `*_character.tres`. Hoje:

| Set | Kits | Total do set completo |
|-----|------|------------------------|
| Leão | Cabeça 4, tronco 4, braço E 4, braço D 4 (nível 1) | 16 |
| Médico | Cabeça 5 (nível 1); tronco 6, braço E 6, braço D 6 (nível 2) | 23 |
| Vampiro | Cabeça 3, tronco 4, braço E 4, braço D 4 (nível 1) | 15 |
| Bruxa | Cabeça 4, tronco 3, braço E 3, braço D 3 (nível 1) | 13 |

A sinergia (2 iguais = 100%, 1 = 50%) está em `scripts/match/synergy.gd`. Dois kits do mesmo set já valem o número cheio; os outros dois iguais somam mais.

A loja lê sozinha as fichas `*_character.tres` em `data/parts/` e vende os 4 kits de cada uma.

## Como marcar os ímãs

1. No Godot, menu **Project → Tools → Ímãs das Peças** (em português: **Projeto → Ferramentas**).
2. No alto, escolha o **Freak**. A janela tem duas abas: **Frente** e **Perfil**.
3. À esquerda, as **6 partes em duas colunas**. À direita, a prévia do Freak montado. A janela abre em tamanho médio; dá para puxar o canto.
4. Em cada parte:
   - a caixa escolhe o que ela é (cabeça, tronco, braço E/D, perna E/D)
   - **Virar** espelha a imagem
   - **Girar** gira o desenho 90°
   - **Z** é a ordem da frente/trás **na carta**: **1 fica na frente**. Exemplo: cabeça 1, tronco 2 → a cabeça cobre o tronco. **Na luta** a ordem é outra: de frente (cabeça, braço E, braço D, tronco, mola) e de perfil (braço D, tronco, cabeça, braço E, mola).
   - **Imagem** escolhe um PNG/WEBP no computador. O jogo grava em **200×200** no lugar da peça.
   - **Ampliar** abre a peça grande. Roda do mouse amplia; botão direito arrasta a imagem; clique duas vezes na miniatura também abre.
5. Arraste as bolinhas até o **centro das esferas de metal**:
   - Cabeça: **BAIXO**
   - Braço / perna: **CIMA**
   - Tronco: **PESCOÇO**, **OE**, **OD**, **QE**, **QD**
6. Clique **Salvar**.

Se os quadros vierem pretos com **sem peça**, feche a janela e abra de novo. Se continuar, feche o Godot e abra o projeto outra vez.

Não use o kit `*_legs.tres` (não tem desenho). A ferramenta lê as 6 imagens de desenho × 2 poses (uma aba cada). As pernas no editor **não aparecem no jogo**; o Freak senta na base-mola.

Marque **frente e perfil**. A carta usa a frente; a luta usa o perfil.

Se uma peça estiver aberta no Inspetor, o botão **Abrir Frente / Perfil deste Freak** abre a mesma tela já nesse Freak.

### Sistema de coordenadas

- Medido em **pixels da textura**, a partir do **centro** da imagem 200×200
- **Y negativo** = para cima
- **Y positivo** = para baixo

### Regra de colagem

1. A base-mola fica no chão da carta, um pouco mais baixa. A esfera de metal é o ímã.
2. Sem tronco: a cabeça cola nessa esfera.
3. Com tronco: o meio dos dois ímãs de quadril cola nessa esfera. A cabeça cola no pescoço.
4. Braços: esfera de cima cola nos ombros. Na **frente**, os braços abrem um pouco, girando nesse ímã (não soltam).

## Arte relacionada

Padrão de arquivos em `assets/characters/<nome>/`:

- `<nome>_head-1.png` / `_body-1` / `_arm_l-1` / `_arm_r-1` / `_leg_l-1` / `_leg_r-1` — frente
- Os mesmos com `-2` — perfil

Todos em **200×200**. No jogo o tamanho fica 1:1 (não estica). A mola fica em `assets/objects/base-mola-solta.png` e `base-mola-pressionada.png` (300×300), **menor** que as peças, com uma sombra oval no chão. Na luta o disco branco senta nos rolos; embaixo da sombra, um recorte mais escuro nos cilindros.

Para colocar um Freak **novo**, veja [Incluir personagem](../incluir-personagem.md).

## Arquivos de dados atuais

Pasta: `data/parts/`

| Arquivo | Conteúdo |
|---------|----------|
| `leao_character.tres` + `leao_head/body/arm_*.tres` | Kits da loja (Leão) |
| `leao_leg_l/r.tres` | Só desenho (pernas ocultas no jogo) |
| `medico_character.tres` + `medico_head/body/arm_*.tres` | Kits da loja (Médico) |
| `medico_leg_l/r.tres` | Só desenho (pernas ocultas no jogo) |
| `vampiro_character.tres` + `vampiro_head/body/arm_*.tres` | Kits da loja (Vampiro) |
| `vampiro_leg_l/r.tres` | Só desenho (pernas ocultas no jogo) |
| `bruxa_character.tres` + `bruxa_head/body/arm_*.tres` | Kits da loja (Bruxa) |
| `bruxa_leg_l/r.tres` | Só desenho (pernas ocultas no jogo) |
