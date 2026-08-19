# Unbox Fighters

Jogo de **abrir caixas**, **montar Freaks** e **lutar na esteira** contra um oponente.  
Feito em **Godot 4.7**. Ainda em construção.

## Como abrir

1. Abra a pasta do projeto no Godot 4.7
2. Rode a cena principal: `scenes/assembly/Assembly.tscn`

Para marcar ímãs (abas Frente e Perfil), incluir, **editar** ou apagar um Freak: **Projeto → Ferramentas** (Project → Tools). Passo a passo em [docs/tecnico/incluir-personagem.md](docs/tecnico/incluir-personagem.md).

## Documentação

Tudo sobre o jogo, mecânicas e como o projeto funciona por dentro:

→ **[docs/INDEX.md](docs/INDEX.md)**

## Estrutura rápida

| Pasta | Conteúdo |
|-------|----------|
| `scenes/` | Telas do jogo |
| `scripts/` | Código |
| `data/` | Dados de personagens e peças |
| `assets/` | Imagens |
| `tools/` | Scripts que preparam arte |
| `docs/` | Documentação |

## Regra de manutenção

Sempre que criar, alterar ou remover algo no projeto, **atualize os docs necessários** no final. Isso está definido como regra sempre ativa no Cursor (`.cursor/rules/atualizar-docs.mdc`).
