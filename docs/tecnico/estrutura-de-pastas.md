# Estrutura de pastas

Onde fica cada tipo de coisa no projeto.

```
unbox-fighters/
├── project.godot          # Configuração do projeto Godot
├── icon.svg
├── README.md
├── docs/                  # Esta documentação
├── assets/                # Arte (imagens)
│   ├── boxes/             # Sprites da caixa (fechada / quebrada)
│   ├── objects/           # Objetos de UI (martelo do cursor)
│   ├── audio/sfx/         # Efeitos sonoros (.wav)
│   ├── characters/leao/
│   ├── characters/vampiro/
│   ├── characters/policial/
│   ├── characters/bruxa/
│   ├── characters/mumia/
│   ├── characters/medico/
│   ├── characters/cachorro/
│   └── ui/
├── data/                  # Dados do jogo (.tres)
│   └── parts/
├── scenes/                # Cenas Godot (.tscn)
│   └── assembly/          # Tela 2D principal
├── scripts/               # Código GDScript (.gd)
│   ├── assembly/          # Tela: cartas, caixas, luta visível, posições
│   ├── match/             # Regras da partida (loja, sinergia, luta)
│   ├── core/
│   ├── data/
│   └── ui/
├── addons/                # Ferramentas do editor (ímãs, incluir personagem)
├── tools/                 # Scripts Python de preparação de arte
└── .cursor/               # Regras e skills do Cursor (assistente) — versão Godot, não Unity
```

As regras em `.cursor/rules/` ensinam o assistente a falar simples, atualizar docs, marcar ímãs, incluir personagem, **fazer cada clique parecer gostoso**, e **mostrar no Godot onde clicar**. Não há regras da Unity neste projeto.

## Guia rápido

| Você quer… | Olhe em… |
|------------|----------|
| Mudar a tela principal | `scenes/assembly/Assembly.tscn` + `scripts/assembly/assembly_controller.gd` |
| Mudar comportamento de caixa / peça / carta | `scripts/assembly/` |
| Mudar atributos ou sprites do vampiro / policial | `data/parts/` |
| Mudar regras de composição visual | `scripts/data/composite_resolver.gd` |
| Mudar regras de luta / loja / bots | `scripts/match/` |
| Mudar HUD / fundo / tags | `scripts/ui/` |
| Preparar imagens 200×200 | `tools/` |
| Incluir um Freak novo | [Incluir personagem](incluir-personagem.md) |
| Documentação | `docs/` |

## Pastas que o Godot gera

- `.godot/` — cache do editor. **Não editar** e normalmente não versionar como conteúdo importante do jogo.
