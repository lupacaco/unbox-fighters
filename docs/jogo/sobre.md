# Sobre o jogo

**Nome:** Unbox Fighters  
**Motor:** Godot 4.7  
**Descrição no projeto:** “Character assembly and unboxing fighters” (montar personagens e lutar)

## Ideia em uma frase

Você compra kits na loja, monta Freaks com **2 kits** (cabeça e corpo, o corpo já traz os braços) em cima de um **caixote**, e na luta eles remam na esteira contra o oponente.

## Loop principal

1. **Preparação (60s):** comprar kits nas 4 prateleiras, montar até 3 Freaks nas cartas
2. Carta com os 2 kits mostra **PRONTO**
3. **Luta:** a loja some, aparecem as 3 cartas do oponente, os Freaks prontos pulam para a esteira em fila
4. Na ponta, a **cabeça ataca**. Quem limpa a esteira causa **5 de dano** na vida do outro por Freak que ainda está de pé
5. Os Freaks **voltam para as cartas**. Nova preparação até a vida de alguém chegar a 0

## Tom visual

Arena de oficina, duas esteiras (azul sua, vermelha do oponente), cartas azuis à esquerda. Na preparação a loja fica à direita; na luta, as cartas vermelhas do oponente.

## Conteúdo atual

- **Personagens na loja:** Bruxa e Advogado
- **3 cartas** suas; **3 cartas** do oponente (só na luta)
- **4 prateleiras** com a peça já visível
- **1 oponente** (um bot que joga com as mesmas regras e o mesmo relógio)

## Resolução da tela

1920×1080, com o jogo se adaptando à janela (`canvas_items`).
