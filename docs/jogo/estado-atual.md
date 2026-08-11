# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (MVP da montagem)

| Área | Situação |
|------|----------|
| Tela de montagem | Funciona como cena principal |
| Abrir caixas | 2 cliques com 3 sprites + cursor martelo + SFX |
| Arrastar e soltar | Mouse, com destaque no encaixe válido + SFX |
| 3 cartas de personagem | Montagem cabeça / tronco / pernas |
| Atributos BRN / PWR / SPD | Somam ao encaixar |
| Visual composto | Usa imagem pré-montada quando possível; senão empilha as 3 partes |
| Fundo de arena | Respiração de vinheta + partículas de poeira |
| Áudio | Efeitos: martelo, caixa, peças, conclusão do lutador |
| Export Web | Scripts `tools/export_web.ps1` + `tools/serve_web.ps1` (localhost) |
| Dados do vampiro | Arquivos `.tres` de personagem e peças |
| Scripts de verificação | Rodam checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| 3 cartas = mesmo personagem | Todas usam `vampiro_character.tres` |
| Loot das 5 caixas | Lista de teste: cabeça, tronco, pernas, cabeça, tronco |
| ThemeTokens | Cores definidas no código, mas pouco (ou não) usadas nas cenas |
| Arte PNG + WEBP | As duas formatos existem para os mesmos sprites |

## Ainda não existe

- Combate / luta
- Multiplayer
- Áudio de música de fundo / menu de volume
- Menus / navegação entre telas
- Salvamento / progressão
- Economia (moeda, loja)
- Elenco de vários personagens
- Controles de gamepad

## Motor e entrada

- **Godot 4.7**, renderer Forward Plus
- Cena principal: `scenes/assembly/Assembly.tscn`
