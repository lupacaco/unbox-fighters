# Incluir um personagem

Este é o jeito certo de colocar um Freak novo no jogo (como Múmia, Médico e Cachorro). Siga **todos** os passos.

As regras da loja, sinergia e luta (o que o jogador vê) estão em [Mecânicas e regras](../jogo/mecanicas-e-regras.md).

O jogador manda uma folha de desenho. O jogo precisa de **9 peças** soltas, números de combate, e uma ficha do personagem. A loja **acha sozinha** qualquer ficha nova em `data/parts/` (não precisa ligar o personagem na tela na mão).

## O que a folha precisa ter

Uma grade **3 × 3**, de preferência **900 × 600** (cada célula já é 300 × 200).

| | Frente (`-1`) | De lado (`-2`) | Golpe (`-3`) |
|---|---|---|---|
| Linha 1 | cabeça de frente | cabeça de perfil | cabeça gritando / atacando |
| Linha 2 | tronco de frente | tronco de lado | tronco socando |
| Linha 3 | pernas de frente | pernas de lado | pernas no passo |

Nome interno (`id` / pasta): minúsculo, sem acento. Exemplos: `mumia`, `medico`, `cachorro`.

Nome na carta: com acento se precisar (`Múmia`, `Médico`, `Cachorro`).

## Duas formas de incluir

### A) No Godot (você mesmo)

1. Menu **Project → Tools → Incluir personagem** (se o Godot estiver em português: **Projeto → Ferramentas**).
2. Escolha a folha PNG ou WEBP.
3. Preencha o id, o nome na carta e os três números (Ameaça / Força / Agilidade).
4. O Godot corta as 9 imagens, cria as fichas e abre a ferramenta de ímãs.

### B) Quando a folha chega no chat (assistente)

1. Cortar a grade com `tools/slice_character_sheet.py` (9 PNG **300×200** transparentes em `assets/characters/{id}/`).
2. Criar as fichas em `data/parts/` (`--write-defs`, ou o menu do Godot).
3. Marcar os ímãs no Godot (passo 2 abaixo). Não chute X = 0.

Não apague todo pixel preto da folha. Só o preto ligado às **bordas** (mancha de dálmata, estetoscópio e olho ficam).

A folha original (`{id}.png` ou `{id}.webp`) pode ficar na mesma pasta. O jogo usa só os 9 recortes.

## 1. Cortar as 9 imagens

Pasta: `assets/characters/{id}/`

Arquivos:

- `{id}_head-1.png` `{id}_head-2.png` `{id}_head-3.png`
- `{id}_body-1.png` `{id}_body-2.png` `{id}_body-3.png`
- `{id}_legs-1.png` `{id}_legs-2.png` `{id}_legs-3.png`

Cada PNG:

- **300 × 200** pixels
- Fundo **transparente**
- Não esticar o desenho. Se a célula for quadrada, encaixar no retângulo com faixa vazia nas laterais

## 2. Pontos de encaixe (ímãs)

Os ímãs dizem onde a cabeça cola no pescoço, as pernas na cintura, e (no tronco) onde a arma vai ficar na mão.

**Não chute os números.** Marque na imagem:

1. No Godot, menu **Project → Tools → Ímãs das Peças**.
2. Na pasta **FileSystem**, clique na peça (`data/parts/cachorro_head.tres`, `medico_body.tres`…).
3. Escolha **Frente**, **De lado** ou **Golpe**.
4. Arraste a bolinha **CIMA** (azul) ou **BAIXO** (vermelha) até o pescoço ou a cintura. No **tronco**, arraste também a bolinha dourada **ARMA** até a mão. Não precisa de botão “marcar”.
5. Salve a ficha (`Ctrl+S`).

Espaço da imagem: o centro do PNG é `(0, 0)`. **Y cresce para baixo.** O X pode ser diferente de 0 se o pescoço ou a mão não estiverem no meio (cabeça de lado, por exemplo).

A prévia embaixo aceita misturar sets: cabeça de cachorro + tronco de médico, para conferir o pescoço. No tronco aparece um ponto dourado no lugar da arma (a arma ainda não existe no jogo).

| Peça | ímã de cima | ímã de baixo | arma |
|------|-------------|--------------|------|
| Cabeça | não usa | base do pescoço | não usa |
| Tronco | coto do pescoço | cintura | mão (bolinha dourada) |
| Pernas | cintura | não usa | não usa |

Marque as **três poses**. A carta usa a frente; a luta usa lado e golpe. Se só a frente estiver marcada, o pescoço de lado fica torto. A arma também muda de lugar no golpe — marque as três.

O mesmo desenho de ímãs também aparece no Inspetor quando você abre uma peça, com o botão **Abrir ferramenta de ímãs (imagem grande)**.

## 3. Números de combate

Se o jogador pedir números, use os dele.

Se não pedir, escolha um conjunto **diferente** dos sets que já existem. Cabeça = Ameaça, tronco = Força, pernas = Agilidade.

O nível da loja sai do número:

| Número | Loja |
|--------|------|
| 3, 4 ou 5 | 1 (sai cedo) |
| 6 | 2 |
| 7 | 3 |
| 8 | 4 |
| 9 | 5 (só no fim) |

Grave os dois: `combat_value` e `tier`.

## 4. Fichas das peças e do personagem

Três peças em `data/parts/`:

- `{id}_head.tres`
- `{id}_body.tres`
- `{id}_legs.tres`

Uma ficha em `data/parts/{id}_character.tres`.

A loja (`ShopPool`) lê **todas** as fichas `*_character.tres` dessa pasta. Set novo entra nas caixas sozinho.

## 5. Documentação

Atualize:

- `docs/tecnico/sistemas/pecas-e-personagens.md` — linha na tabela
- `docs/jogo/estado-atual.md` — lista de personagens
- `docs/tecnico/estrutura-de-pastas.md` — nome do set na pasta de arte
- Este arquivo, se o fluxo mudar

## 6. Conferir

- Os 9 PNG são 300 × 200 e têm transparência de verdade
- Preto de dentro do desenho (mancha, olho, tubo) não sumiu
- Play: peça na caixa, encaixa na carta, set completo mostra o nome certo
- Loja: peça 3–5 no nível 1; peça 9 só no nível 5

## Sets que já passaram por este fluxo

| id | Nome | Números |
|----|------|---------|
| `vampiro` | Vampiro | 9 / 9 / 8 |
| `policial` | Policial | 7 / 6 / 5 |
| `bruxa` | Bruxa | 9 / 4 / 9 |
| `mumia` | Múmia | 5 / 8 / 6 |
| `medico` | Médico | 3 / 4 / 4 |
| `cachorro` | Cachorro | 5 / 5 / 7 |
