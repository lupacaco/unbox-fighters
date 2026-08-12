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
| Visual composto | Só partes separadas; ímãs (`magnet_up` / `magnet_down`) unem as peças |
| Botão LUTAR | Aparece no policial completo; animação de salto + perfil + ataques bumerangue no shelf |
| Fundo de arena | Respiração de vinheta + partículas de poeira |
| Áudio | Efeitos: martelo, caixa, peças, conclusão do lutador |
| Export Web | Scripts `tools/export_web.ps1` + `tools/serve_web.ps1` (localhost) |
| Dados do vampiro, policial e bruxa | Arquivos `.tres` de personagem e peças |
| Scripts de verificação | Rodam checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| 3 cartas | Cartas em branco: qualquer peça encaixa em qualquer carta |
| Loot das 9 caixas | Set completo vampiro + policial + bruxa |
| Botão LUTAR | Libera quando as 3 peças encaixadas têm poses de perfil/ataque |
| ThemeTokens | Cores definidas no código, mas pouco (ou não) usadas nas cenas |
| Arte no padrão `-1/-2/-3` | Frente / perfil / ataque por peça |

## Ainda não existe

- Combate / luta com oponente (existe só animação solo no shelf)
- Multiplayer
- Áudio de música de fundo / menu de volume
- Menus / navegação entre telas
- Salvamento / progressão
- Economia (moeda, loja)
- Elenco grande de personagens (hoje: vampiro, policial, bruxa)
- Controles de gamepad

## Motor e entrada

- **Godot 4.7**, renderer Forward Plus
- Cena principal: `scenes/assembly/Assembly.tscn`
- Cópia Unity (só montagem, para benchmark): pasta irmã `C:\dev\unbox-fighters-unity` — ver [Unity benchmark](../tecnico/unity-benchmark.md)
