# Estrutura de pastas

Onde fica cada tipo de coisa no projeto.

```
unbox-fighters/
├── project.godot          # Configuração do projeto Godot
├── icon.svg
├── README.md
├── docs/                  # Esta documentação
├── assets/                # Arte (imagens)
│   ├── boxes/             # Sprites da caixa (intacta / trincada / quebrada)
│   ├── objects/           # Objetos de UI (martelo do cursor)
│   ├── characters/vampiro/
│   └── ui/
├── data/                  # Dados do jogo (.tres)
│   └── parts/
├── scenes/                # Cenas Godot (.tscn)
│   └── assembly/
├── scripts/               # Código GDScript (.gd)
│   ├── assembly/
│   ├── core/
│   ├── data/
│   └── ui/
├── tools/                 # Scripts Python de preparação de arte
└── .cursor/               # Regras e skills do Cursor (assistente)
```

## Guia rápido

| Você quer… | Olhe em… |
|------------|----------|
| Mudar a tela principal | `scenes/assembly/Assembly.tscn` + `scripts/assembly/assembly_controller.gd` |
| Mudar comportamento de caixa / peça / carta | `scripts/assembly/` |
| Mudar atributos ou sprites do vampiro | `data/parts/` |
| Mudar regras de composição visual | `scripts/data/composite_resolver.gd` |
| Mudar HUD / fundo | `scripts/ui/` |
| Preparar imagens 300×300 | `tools/` |
| Documentação | `docs/` |

## Pastas que o Godot gera

- `.godot/` — cache do editor. **Não editar** e normalmente não versionar como conteúdo importante do jogo.
