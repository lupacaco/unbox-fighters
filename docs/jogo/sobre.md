# Sobre o jogo

**Nome:** Unbox Fighters  
**Motor:** Godot 4.7  
**Descrição no projeto:** “Character assembly and unboxing fighters” (montar personagens e abrir caixas de lutadores)

## Ideia em uma frase

Você abre caixas, monta Freaks com **3 kits** (cabeça, tronco com os braços, pernas juntas) e eles lutam sozinhos em fila contra bots. Por baixo, o desenho ainda tem 6 membros, para andar e atacar como marionete.

## Loop principal

1. **Abrir** caixas na loja (gasta pancadas)
2. **Montar** até 3 Freaks nas cartas
3. **Lutar** em auto-battle (parte contra parte, de cima para baixo)

## Tom visual

Arena escura, prateleira como palco, tags coloridas com os números, spotlight no choque do centro.

## Conteúdo atual

- **6 personagens:** Vampiro, Policial, Bruxa, Múmia, Médico e Cachorro
- **3 cartas** (fila 3º / 2º / 1º)
- **5 caixas** por rodada, com nível de loja
- **3 bots** na mesma partida

## Resolução da tela

1920×1080, com o jogo se adaptando à janela (`canvas_items`).
