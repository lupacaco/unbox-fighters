# Documentação — Unbox Fighters

Índice de tudo que está documentado sobre o jogo.

O jogo ainda **não está pronto**. Estes docs descrevem o que **já existe** hoje. Quando algo for criado, alterado ou removido no projeto, os docs certos devem ser atualizados.

---

## Para entender o jogo

| Doc | O que contém |
|-----|----------------|
| [Sobre o jogo](jogo/sobre.md) | Ideia do jogo, proposta e loop principal |
| [Mecânicas e regras](jogo/mecanicas-e-regras.md) | Dinheiro, loja, sinergia, esteiras e luta |
| [Estado atual](jogo/estado-atual.md) | O que já está feito e o que ainda não existe |

## Para entender como o projeto é feito por dentro

| Doc | O que contém |
|-----|----------------|
| [Arquitetura](tecnico/arquitetura.md) | Como as partes do programa se encaixam |
| [Estrutura de pastas](tecnico/estrutura-de-pastas.md) | Onde fica cada tipo de arquivo |
| [Partida](tecnico/sistemas/partida.md) | Jogo corrido 1 contra 1, dinheiro, esteira, duelo |
| [Tela de montagem](tecnico/sistemas/tela-de-montagem.md) | Cartas, prateleiras, esteiras, barra de dinheiro |
| [Peças e personagens](tecnico/sistemas/pecas-e-personagens.md) | Dados dos personagens, sinergia e composição visual |
| [Incluir personagem](tecnico/incluir-personagem.md) | Folha 4+4 → 8 PNG 200×200, 3 kits na loja, ímãs |
| [Arrastar e soltar](tecnico/sistemas/arrastar-e-soltar.md) | Peças da prateleira para a carta, vender |
| [Animação de luta](tecnico/sistemas/animacao-de-luta.md) | Deslize na esteira, cabeça que voa, morte no vão |
| [Visual e UI](tecnico/sistemas/visual-e-ui.md) | Fundo, cartas, prateleiras, barras, botões |
| [Áudio](tecnico/sistemas/audio.md) | Efeitos gravados: caixa, ímã, luta |
| [Pipeline de arte](tecnico/pipeline-de-arte.md) | Scripts que preparam imagens dos personagens |
| [Testes rápidos](tecnico/testes-headless.md) | Scripts que verificam o jogo sem abrir a tela |
| [Plataformas](tecnico/plataformas.md) | Web / localhost, Steam e Google Play |
| [Godot MCP](tecnico/godot-mcp.md) | Ligar a IA ao editor Godot |

---

## Manutenção

Regra do projeto: **sempre que implementar, alterar ou remover algo, atualizar os docs necessários no final da tarefa.**

Veja também o [README](../README.md) na raiz do projeto.
