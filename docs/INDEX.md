# Documentação — Unbox Fighters

Índice de tudo que está documentado sobre o jogo.

O jogo ainda **não está pronto**. Estes docs descrevem o que **já existe** hoje. Quando algo for criado, alterado ou removido no projeto, os docs certos devem ser atualizados.

---

## Para entender o jogo

| Doc | O que contém |
|-----|----------------|
| [Sobre o jogo](jogo/sobre.md) | Ideia do jogo, proposta e loop principal |
| [Mecânicas e regras](jogo/mecanicas-e-regras.md) | Loja, pancadas, sinergia, luta em fila |
| [Estado atual](jogo/estado-atual.md) | O que já está feito e o que ainda não existe |

## Para entender como o projeto é feito por dentro

| Doc | O que contém |
|-----|----------------|
| [Arquitetura](tecnico/arquitetura.md) | Como as partes do programa se encaixam |
| [Estrutura de pastas](tecnico/estrutura-de-pastas.md) | Onde fica cada tipo de arquivo |
| [Partida (auto-battle)](tecnico/sistemas/partida.md) | Rodada, loja, bots, simulador de luta |
| [Tela de montagem](tecnico/sistemas/tela-de-montagem.md) | Prep, loja e cartas |
| [Peças e personagens](tecnico/sistemas/pecas-e-personagens.md) | Dados dos personagens, sinergia e composição visual |
| [Incluir personagem](tecnico/incluir-personagem.md) | Folha 6+6 → 12 PNG 200×200, 3 kits na loja, ímãs |
| [Arrastar e soltar](tecnico/sistemas/arrastar-e-soltar.md) | Peças, troca de fila e vender |
| [Animação de luta](tecnico/sistemas/animacao-de-luta.md) | Palco: um contra um, pulo, caminhada, golpes, KO |
| [Visual e UI](tecnico/sistemas/visual-e-ui.md) | PREP, tags, pancadas, fundo |
| [Áudio](tecnico/sistemas/audio.md) | Efeitos gravados: caixa, ímã, luta |
| [Pipeline de arte](tecnico/pipeline-de-arte.md) | Scripts que preparam imagens dos personagens |
| [Testes rápidos](tecnico/testes-headless.md) | Scripts que verificam o jogo sem abrir a tela |
| [Plataformas](tecnico/plataformas.md) | Web / localhost, Steam e Google Play |
| [Godot MCP](tecnico/godot-mcp.md) | Ligar a IA ao editor Godot |

---

## Manutenção

Regra do projeto: **sempre que implementar, alterar ou remover algo, atualizar os docs necessários no final da tarefa.**

Veja também o [README](../README.md) na raiz do projeto.
