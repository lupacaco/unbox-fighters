# Sobre o jogo

**Nome:** Unbox Fighters  
**Motor:** Godot 4.7  
**Descrição no projeto:** “Character assembly and unboxing fighters” (montar personagens e abrir caixas de lutadores)

## Ideia em uma frase

Você abre caixas, monta Freaks com **3 kits** (cabeça, tronco e os dois braços juntos) em cima de um **caixote**, e manda eles remarem na esteira para lutar contra o oponente.

## Loop principal

1. **Comprar** kits nas prateleiras (gasta dinheiro)
2. **Montar** até 2 Freaks nas cartas
3. **LUTAR**: o Freak completo pula da carta para a esteira azul e rema até a ponta
4. Na ponta, a **cabeça ataca**. Se ficar sozinho, vai comendo a vida do outro jogador

## Tom visual

Arena de oficina, duas esteiras (azul sua, vermelha do oponente), cartas de madeira à esquerda, loja no meio, dinheiro à direita.

## Conteúdo atual

- **Personagens na loja:** Bruxa e Advogado
- **2 cartas** para montar
- **4 prateleiras** de loja
- **1 oponente** (um bot que joga com as mesmas regras)

## Resolução da tela

1920×1080, com o jogo se adaptando à janela (`canvas_items`).
