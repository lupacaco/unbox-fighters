# Incluir um personagem

Este é o jeito certo de colocar um Freak novo no jogo. Siga **todos** os passos.

As regras da loja, sinergia e luta (o que o jogador vê) estão em [Mecânicas e regras](../jogo/mecanicas-e-regras.md).

O jogador manda uma folha de desenho. O jogo precisa de **12 recortes** (6 de frente + 6 de perfil) para animar, **3 fichas na loja** (cabeça, tronco com braços, pernas juntas), e uma ficha do personagem. A loja **acha sozinha** qualquer ficha nova em `data/parts/` (depois filtra pelos sets ativos).

## O que a folha precisa ter

**6 partes de frente** e **6 de perfil**, cada uma solta (não grudada na vizinha).

Pode ser **frente à esquerda e perfil à direita**, ou **frente em cima e perfil embaixo**.

As 6 partes:

1. Cabeça
2. Tronco (com **5 esferas** de metal: pescoço, dois ombros, dois quadris)
3. Braço esquerdo (de quem olha)
4. Braço direito
5. Perna esquerda
6. Perna direita

Cabeça, braços e pernas têm **1 esfera** cada, no ponto de união.

Nome interno (`id` / pasta): minúsculo, sem acento. Exemplo: `leao`.

Nome na carta: com acento se precisar (`Leão`).

## Duas formas de incluir

### A) No Godot (você mesmo)

1. Menu **Project → Tools → Incluir personagem** (se o Godot estiver em português: **Projeto → Ferramentas**).
2. Escolha a folha PNG ou WEBP.
3. Preencha o id, o nome na carta e os **3 números** da loja (Cabeça, Tronco, Pernas).
4. O Godot corta as 12 imagens, cria as fichas e abre a ferramenta de ímãs.

### B) Quando a folha chega no chat (assistente)

1. Cortar com `tools/slice_character_sheet.py` (12 PNG **200×200** transparentes em `assets/characters/{id}/`).
2. Criar as fichas em `data/parts/` (`--write-defs`, ou o menu do Godot).
3. Marcar os ímãs no Godot (passo 2 abaixo). Não chute X = 0.

Não apague todo pixel preto da folha. Só o preto ligado às **bordas**.

A folha original pode ficar em `assets/characters/{id}/`. O jogo usa os 12 recortes.

## 1. Cortar as 12 imagens

Pasta: `assets/characters/{id}/`

Arquivos (`-1` = frente, `-2` = perfil):

- `{id}_head-1.png` `{id}_head-2.png`
- `{id}_body-1.png` `{id}_body-2.png`
- `{id}_arm_l-1.png` `{id}_arm_l-2.png`
- `{id}_arm_r-1.png` `{id}_arm_r-2.png`
- `{id}_leg_l-1.png` `{id}_leg_l-2.png`
- `{id}_leg_r-1.png` `{id}_leg_r-2.png`

Cada PNG:

- **200 × 200** pixels
- Fundo **transparente**
- Não esticar o desenho. Encaixar no quadrado, proporcional

Comando:

```
python tools/slice_character_sheet.py CAMINHO_DA_FOLHA --id ID --name NOME --value 4 --write-defs
```

## 2. Pontos de encaixe (ímãs)

Os ímãs dizem onde cada esfera de metal cola na vizinha.

**Não chute os números.** Marque na imagem:

1. No Godot, menu **Project → Tools → Ímãs das Peças** (em português: **Projeto → Ferramentas**).
2. No alto da janela, escolha o **Freak** (ex.: Leão).
3. Use a aba **Frente** e a aba **Perfil**. As 6 partes ficam em duas colunas compactas. À direita: a prévia. A janela cabe na tela do Godot; arraste o canto se quiser maior.
4. Se um desenho estiver no tipo errado, escolha o certo na caixa (ex.: Perna E). **Virar** e **Girar** corrigem a imagem. **Z** 1 fica na frente **na carta**. Na luta a ordem é fixa (cabeça, braço D, tronco, perna D, perna E, braço E). **Imagem** escolhe um arquivo do PC. **Ampliar** abre a peça grande para marcar o ímã com precisão (roda do mouse amplia).
5. Arraste cada bolinha até o **centro da esfera de metal**.
6. Clique **Salvar**. Cada bolinha que você solta também já grava aquela peça.

Se os quadros vierem pretos com **sem peça**, feche a janela e abra de novo. Se continuar, feche o Godot por completo e abra o projeto outra vez.

Espaço da imagem: o centro do PNG é `(0, 0)`. **Y cresce para baixo.**

| Peça | Ímãs |
|------|------|
| Cabeça | 1: BAIXO (base do pescoço) |
| Tronco | 5: PESCOÇO, OE (ombro esquerdo), OD, QE (quadril esquerdo), QD |
| Braço / perna | 1: CIMA (topo da peça) |

Marque **frente e perfil** nas duas abas. A carta usa a frente; a luta usa o lado. Se só a frente estiver marcada, o pescoço de lado fica torto.

Se você estiver com uma peça aberta no Inspetor, o botão **Abrir Frente / Perfil deste Freak** abre a mesma janela já no Freak certo.

## 3. Números de combate

Se o jogador pedir números, use os dele.

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

Doze recortes viram **6 fichas de desenho** + **1 kit de pernas da loja** + a ficha do personagem:

- Desenho: `{id}_head.tres` `{id}_body.tres` `{id}_arm_l.tres` `{id}_arm_r.tres` `{id}_leg_l.tres` `{id}_leg_r.tres`
- Loja: `{id}_head.tres` `{id}_body.tres` `{id}_legs.tres` (as duas pernas juntas; sem PNG próprio)
- Personagem: `{id}_character.tres`

A loja (`ShopPool`) lê as fichas `*_character.tres` e vende só os 3 kits. Braços e pernas soltos não entram nas caixas. Para um teste com um set só, `ACTIVE_SET_IDS` lista esse id. Lista vazia = todos os sets.

## 5. Documentação

Atualize:

- `docs/tecnico/sistemas/pecas-e-personagens.md` — linha na tabela
- `docs/jogo/estado-atual.md` — lista de personagens
- `docs/tecnico/estrutura-de-pastas.md` — nome do set na pasta de arte
- Este arquivo, se o fluxo mudar

## 6. Conferir

- Os 12 PNG são 200 × 200 e têm transparência de verdade
- Preto de dentro do desenho não sumiu
- Play: kit na caixa (tronco já com braços, pernas juntas), encaixa na carta, set completo (3 kits) mostra o nome certo
- Tronco tem 5 ímãs visíveis na ferramenta

## Sets que já passaram por este fluxo

| id | Nome | Números |
|----|------|---------|
| `leao` | Leão | 4 nos 3 kits da loja (nível 1, total 12) |
| `medico` | Médico | Cabeça 5 (nível 1), tronco 6 (nível 2), pernas 4 (nível 1). Total 15 |
