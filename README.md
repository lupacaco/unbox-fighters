# Unbox Fighters

Jogo de **abrir caixas** e **montar lutadores** (cabeça, tronco e pernas).  
Feito em **Godot 4.7**. Ainda em construção: hoje existe a tela de montagem; o combate ainda não.

## Como abrir

1. Abra a pasta do projeto no Godot 4.7
2. Rode a cena principal: `scenes/assembly/Assembly.tscn`

Para ver as **pernas 3D do policial dando passos**, rode `scenes/preview/LegsWalkPreview.tscn` (F6). Isso não substitui a tela principal.

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
