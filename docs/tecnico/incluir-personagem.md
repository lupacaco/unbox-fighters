# Incluir um personagem

Este é o jeito certo de colocar um Freak novo no jogo. Siga **todos** os passos.

As regras da loja, sinergia e luta (o que o jogador vê) estão em [Mecânicas e regras](../jogo/mecanicas-e-regras.md).

O jogador manda uma folha de desenho. O jogo precisa de **8 recortes** (4 de frente + 4 de perfil), **2 kits na loja** (cabeça e corpo; o corpo já traz os braços), e uma ficha do personagem. O **caixote é a base de todos** (`assets/nova-ui/caixote.png`), não vem no tronco. Não tem pernas. A loja **acha sozinha** qualquer ficha nova em `data/parts/`.

## O que a folha precisa ter

**4 partes de frente** e **4 de perfil**, cada uma solta (não grudada na vizinha).

Pode ser **frente à esquerda e perfil à direita**, ou **frente em cima e perfil embaixo**.

As 4 partes:

1. Cabeça
2. Tronco (com **4 esferas** de metal: pescoço, dois ombros, e uma embaixo que encaixa no caixote)
3. Braço esquerdo (de quem olha)
4. Braço direito

Cabeça e braços têm **1 esfera** cada, no ponto de união.

Nome interno (`id` / pasta): minúsculo, sem acento. Exemplo: `bruxa`.

Nome na carta: com acento se precisar (`Bruxa`).

## Duas formas de incluir

### A) No Godot (você mesmo)

1. Menu **Project → Tools → Incluir personagem** (se o Godot estiver em português: **Projeto → Ferramentas**).
2. Escolha a folha PNG ou WEBP.
3. Preencha o id, o nome na carta, os **2 números** (Ataque e HP), o **tipo** e o **Poder**.
4. Clique **Cortar e criar**. A janela **fica aberta** e mostra o que está acontecendo. Se a folha estiver errada, o texto fica vermelho na mesma janela. Se der certo, abre a ferramenta de ímãs.

Todas as janelas de **Projeto → Ferramentas** (incluir, editar, apagar, ímãs e ampliar) abrem em **800 × 600**. Se o conteúdo for mais alto, aparece uma barra para rolar.

### B) Quando a folha chega no chat (assistente)

1. Cortar com `tools/slice_character_sheet.py` (8 PNG **200×200** transparentes em `assets/characters/{id}/`, mais um `{id}_slice.json` com os ímãs que o script achou).
2. Gerar as fichas com `godot --headless --path . --script scripts/core/import_roster.gd`.
3. Conferir os ímãs no Godot (passo 2 abaixo). Não chute X = 0.

Não apague todo pixel preto da folha. Só o preto ligado às **bordas**. Se o Freak tem **roupa preta**, a folha precisa ser **PNG com fundo transparente**. JPG com fundo preto mistura a roupa com o fundo e o corte falha.

A folha original pode ficar em `assets/characters/{id}/`. O jogo usa os 8 recortes.

## 1. Cortar as 8 imagens

Pasta: `assets/characters/{id}/`

Arquivos (`-1` = frente, `-2` = perfil):

- `{id}_head-1.png` `{id}_head-2.png`
- `{id}_body-1.png` `{id}_body-2.png`
- `{id}_arm_l-1.png` `{id}_arm_l-2.png`
- `{id}_arm_r-1.png` `{id}_arm_r-2.png`

Cada PNG:

- **200 × 200** pixels
- Fundo **transparente**
- Não esticar o desenho. Encaixar no quadrado, proporcional

Comando:

```
python tools/slice_character_sheet.py CAMINHO_DA_FOLHA --id ID --name NOME --attack 8 --hp 15 --kind supernatural --overlay
godot --headless --path . --script scripts/core/import_roster.gd
```

`--overlay` grava uma foto de conferência em `tools/checks/` (o Godot não importa essa pasta).

## 2. Pontos de encaixe (ímãs)

Os ímãs dizem onde cada esfera de metal cola na vizinha.

**Não chute os números.** Marque na imagem:

1. No Godot, menu **Project → Tools → Ímãs das Peças** (em português: **Projeto → Ferramentas**).
2. No alto da janela, escolha o **Freak** (ex.: Bruxa).
3. Use a aba **Frente** e a aba **Perfil**. As 4 partes ficam em duas colunas. À direita: a prévia.
4. Se um desenho estiver no tipo errado, escolha o certo na caixa (ex.: Braço E). **Virar** e **Girar** corrigem a imagem. **Z** 1 fica na frente **na carta**. **Imagem** escolhe o PNG desta peça na pasta do Freak. Se errar, **Trocar** escolhe outro — a pasta fica igual. **Ampliar** abre a peça grande para marcar o ímã com precisão (roda do mouse amplia).
5. Arraste cada bolinha até o **centro da esfera de metal**.
6. Clique **Salvar**. Cada bolinha que você solta também já grava aquela peça.

Se os quadros vierem pretos com **sem peça**, feche a janela e abra de novo. Se continuar, feche o Godot por completo e abra o projeto outra vez.

Espaço da imagem: o centro do PNG é `(0, 0)`. **Y cresce para baixo.**

| Peça | Ímãs |
|------|------|
| Cabeça | 1: BAIXO (base do pescoço) |
| Tronco | 4: PESCOÇO, OE (ombro esquerdo), OD, CAIXOTE (esfera de baixo) |
| Braço | 1: CIMA (topo da peça) |

Marque **frente e perfil** nas duas abas. A carta usa a frente; a esteira usa o lado.

Se você estiver com uma peça aberta no Inspetor, o botão **Abrir Frente / Perfil deste Freak** abre a mesma janela já no Freak certo.

## 3. Números de combate

Se o jogador pedir números, use os dele.

| Kit | Faixa | Preço |
|-----|-------|-------|
| Cabeça = Ataque | 1 a 10 | o próprio Ataque |
| Corpo = HP | 10 a 20 | HP − 10 (mínimo $1) |

Grave `stat_value` (o número) em cada kit. O preço a loja calcula sozinha.

## 4. Fichas das peças e do personagem

Oito recortes viram **4 fichas de desenho** + a ficha do personagem:

- Desenho: `{id}_head.tres` `{id}_body.tres` `{id}_arm_l.tres` `{id}_arm_r.tres`
- Loja: cabeça e corpo (os braços vêm no corpo)
- Personagem: `{id}_character.tres` (tipo + Poder)

A loja lê sozinha as fichas `*_character.tres` em `data/parts/` e vende os 2 kits de cada Freak. Freak novo entra no Play seguinte, sem lista na mão.

## 5. Documentação

Atualize:

- `docs/tecnico/sistemas/pecas-e-personagens.md` — linha na tabela
- `docs/jogo/estado-atual.md` — lista de personagens
- `docs/tecnico/estrutura-de-pastas.md` — nome do set na pasta de arte
- Este arquivo, se o fluxo mudar

## 6. Conferir

- Os 8 PNG são 200 × 200 e têm transparência de verdade
- Preto de dentro do desenho não sumiu
- Play: o corpo traz os **dois** braços; o tronco senta **dentro** do caixote da carta; set completo (cabeça + corpo do mesmo Freak) liga o Poder
- Tronco tem 4 ímãs visíveis na ferramenta (pescoço, ombros, chão)

## 7. Remover um personagem

Para tirar um Freak **inteiro** do jogo (desenhos, pasta e fichas da loja):

1. Menu **Project → Tools → Remover personagem** (em português: **Projeto → Ferramentas**).
2. Escolha o Freak na lista. A janela mostra a cara dele e os arquivos que vão sumir.
3. Clique **Apagar este Freak**.
4. Confirme **Apagar de vez**.

A loja deixa de vender esse Freak no **próximo Play**. Não dá para desfazer no Godot.

A ferramenta também acha Freak **incompleto** (pasta de desenhos sem ficha na loja). Folhas soltas na pasta `assets/characters/` com o mesmo nome (JPG/PNG) saem junto.

Pelo terminal, o mesmo apagar:

```
godot --headless --path . --script scripts/core/remove_character.gd -- ID
```

Depois de apagar, atualize as tabelas dos docs se esse Freak estava listado.

Não apague os arquivos na mão: é fácil esquecer uma ficha e a loja continuar vendendo um Freak pela metade.

## 8. Editar um personagem

Para mudar o **nome na carta**, o **tipo**, o **Poder**, o **Ataque** ou o **HP** de um Freak que já existe:

1. Menu **Project → Tools → Editar personagem** (em português: **Projeto → Ferramentas**).
2. Escolha o Freak na lista. A janela mostra a cara, os números e o preço na loja.
3. Mude o que quiser e clique **Salvar**.
4. Vale no **próximo Play**. Os ímãs e os desenhos ficam como estão.

O **id interno** (o nome da pasta, ex.: `bruxa`) **não muda** por aqui. Para trocar a pasta, apague e inclua de novo. Para mexer nos ímãs, use o botão **Abrir ímãs deste Freak** na mesma janela.

Pelo terminal:

```
godot --headless --path . --script scripts/core/edit_character.gd -- bruxa
godot --headless --path . --script scripts/core/edit_character.gd -- bruxa --attack 9 --hp 16 --name Bruxa --kind supernatural --ability mind_control
```

Depois de mudar Ataque, HP, tipo ou Poder, atualize a tabela em [Peças e personagens](sistemas/pecas-e-personagens.md) se esses números estiverem escritos lá.

## Sets que já passaram por este fluxo

| id | Nome | Tipo | Ataque | HP | Poder |
|----|------|------|--------|----|-------|
| `bruxa` | Bruxa | Sobrenatural | 8 | 15 | Controle de Mente |
| `advogado` | Advogado | Humano | 4 | 18 | Recurso |
