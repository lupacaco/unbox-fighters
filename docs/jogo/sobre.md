# Sobre o jogo

**Nome:** Unbox Fighters  
**Motor:** Godot 4.7  
**Descrição no projeto:** “Character assembly and unboxing fighters” (montar personagens e abrir caixas de lutadores)

## Ideia em uma frase

Você abre caixas, pega partes do corpo (cabeça, tronco e pernas) e monta lutadores nas cartas.

## Loop principal (visão do produto)

1. **Abrir** caixas (unbox)
2. **Montar** lutadores com as peças
3. **Lutar** com os personagens montados *(ainda não implementado)*

Hoje só a parte de **abrir + montar** existe na tela de montagem (assembly). Assembly = a tela onde você monta os lutadores.

## Tom visual

Visual “premium”: cartas, prateleira, caixas e fundo de arena com poeira. A intenção é parecer uma arena de luta, mesmo antes do combate existir.

## Conteúdo atual

- **1 personagem de dados:** Vampiro (`vampiro`)
- **3 cartas** na tela (as três usam o mesmo personagem, por enquanto)
- **5 caixas** na prateleira com peças de recompensa

## Resolução da tela

1920×1080, com o jogo se adaptando à janela (`canvas_items`).
