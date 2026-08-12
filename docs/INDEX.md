# Documentação — Unbox Fighters

Índice de tudo que está documentado sobre o jogo.

O jogo ainda **não está pronto**. Estes docs descrevem o que **já existe** hoje. Quando algo for criado, alterado ou removido no projeto, os docs certos devem ser atualizados.

---

## Para entender o jogo

| Doc | O que contém |
|-----|----------------|
| [Sobre o jogo](jogo/sobre.md) | Ideia do jogo, proposta e loop principal |
| [Mecânicas e regras](jogo/mecanicas-e-regras.md) | Como funciona abrir caixas, montar lutadores e atributos |
| [Estado atual](jogo/estado-atual.md) | O que já está feito e o que ainda não existe |

## Para entender como o projeto é feito por dentro

| Doc | O que contém |
|-----|----------------|
| [Arquitetura](tecnico/arquitetura.md) | Como as partes do programa se encaixam |
| [Estrutura de pastas](tecnico/estrutura-de-pastas.md) | Onde fica cada tipo de arquivo |
| [Tela de montagem](tecnico/sistemas/tela-de-montagem.md) | Cena principal: caixas, cartas e peças |
| [Peças e personagens](tecnico/sistemas/pecas-e-personagens.md) | Dados dos personagens e composição visual |
| [Arrastar e soltar](tecnico/sistemas/arrastar-e-soltar.md) | Como o jogador move peças para as cartas |
| [Animação de luta](tecnico/sistemas/animacao-de-luta.md) | Botão LUTAR e showcase no shelf (sem oponente ainda) |
| [Visual e UI](tecnico/sistemas/visual-e-ui.md) | Interface, fundo, cores e sprites das caixas |
| [Áudio](tecnico/sistemas/audio.md) | Efeitos sonoros (caixa, peças, conclusão) |
| [Pipeline de arte](tecnico/pipeline-de-arte.md) | Scripts que preparam imagens dos personagens |
| [Testes rápidos](tecnico/testes-headless.md) | Scripts que verificam o jogo sem abrir a tela |
| [Plataformas](tecnico/plataformas.md) | Web / localhost, Steam e Google Play |
| [Godot MCP](tecnico/godot-mcp.md) | Ligar a IA ao editor Godot |
| [Unity (benchmark)](tecnico/unity-benchmark.md) | Cópia Unity da tela de montagem para comparar desempenho |
| [Teste 3D (policial)](tecnico/sistemas/teste-3d-policial.md) | Montagem completa só com o policial em 3D (Godot e Unity) |

---

## Manutenção

Regra do projeto: **sempre que implementar, alterar ou remover algo, atualizar os docs necessários no final da tarefa.**

Veja também o [README](../README.md) na raiz do projeto.
