# Sobre o jogo

**Nome:** Unbox Fighters  
**Motor:** Godot 4.7  
**Descrição no projeto:** “Character assembly and unboxing fighters” (montar personagens e abrir caixas de lutadores)

## Ideia em uma frase

Você abre caixas, monta Freaks com **2 kits** (cabeça e corpo, o corpo já traz os braços) em cima de um **caixote**, e manda eles remarem na esteira para lutar contra o oponente.

## Loop principal

1. **Comprar** kits nas prateleiras (gasta dinheiro)
2. **Montar** até 2 Freaks nas cartas
3. **LUTAR**: o Freak completo pula da carta para a esteira azul e rema até a ponta
4. Na ponta, a **cabeça ataca**. Se ficar sozinho, empurra a barra-balança para o lado dele

## Tom visual

Arena de oficina, duas esteiras (azul sua, vermelha do oponente), cartas azuis à esquerda, cartas vermelhas à direita, loja no meio.

## Conteúdo atual

- **Personagens na loja:** Bruxa e Advogado
- **2 cartas** suas e **2 cartas** do oponente
- **1 prateleira** de loja no meio
- **1 oponente** (um bot que joga com as mesmas regras)

## Resolução da tela

1920×1080, com o jogo se adaptando à janela (`canvas_items`).
