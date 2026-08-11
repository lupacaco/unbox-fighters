# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (MVP da montagem)

| Área | Situação |
|------|----------|
| Tela de montagem | Funciona como cena principal |
| Abrir caixas | 2 cliques com 3 sprites + cursor martelo no hover/batida |
| Arrastar e soltar | Mouse, com destaque no encaixe válido |
| 3 cartas de personagem | Montagem cabeça / tronco / pernas |
| Atributos BRN / PWR / SPD | Somam ao encaixar |
| Visual composto | Usa imagem pré-montada quando possível; senão empilha as 3 partes |
| Fundo de arena | Respiração de vinheta + partículas de poeira |
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
- Áudio
- Menus / navegação entre telas
- Salvamento / progressão
- Economia (moeda, loja)
- Elenco de vários personagens
- Controles de gamepad

## Motor e entrada

- **Godot 4.7**, renderer Forward Plus
- Cena principal: `scenes/assembly/Assembly.tscn`
