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
│   ├── audio/sfx/         # Efeitos sonoros (.wav)
│   ├── characters/vampiro/
│   ├── characters/policial/
│   │   └── 3d/            # GLB do policial (teste 3D)
│   ├── characters/bruxa/
│   └── ui/
├── data/                  # Dados do jogo (.tres)
│   └── parts/
├── scenes/                # Cenas Godot (.tscn)
│   ├── assembly/          # Tela 2D principal
│   └── assembly3d/        # Teste 3D (só policial)
├── scripts/               # Código GDScript (.gd)
│   ├── assembly/
│   ├── assembly3d/
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
| Mudar atributos ou sprites do vampiro / policial | `data/parts/` |
| Mudar regras de composição visual | `scripts/data/composite_resolver.gd` |
| Mudar HUD / fundo | `scripts/ui/` |
| Preparar imagens 300×300 | `tools/` |
| Teste 3D do policial | `scenes/assembly3d/Assembly3D.tscn` (F6) |
| Documentação | `docs/` |

## Pastas que o Godot gera

- `.godot/` — cache do editor. **Não editar** e normalmente não versionar como conteúdo importante do jogo.
