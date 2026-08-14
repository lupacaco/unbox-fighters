# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (MVP do auto-battle contra bots)

| Área | Situação |
|------|----------|
| Partida contra 3 bots | 4 vivos, HP 40, último de pé ganha. Bots: Sombra, Ferrugem, Névoa |
| Preparação | Até 60 s (relógio `1:00`) ou botão PRONTO |
| Loja | 5 caixas, pancadas douradas, atualizar, travar (caixas azuis), vender à direita, subir nível |
| Montagem | 3 cartas (3º / 2º / 1º), misturar peças, carta incompleta vale |
| Luta em fila | Choque parte contra parte, cópia das cartas, teto de 12 de dano por Freak |
| Tela de luta | Os dois Freaks entram juntos; pulo, caminhada na mesma linha, placas, resto do choque, KO |
| Fim de partida | **Você venceu!** / **Você saiu** e botão **NOVA PARTIDA** |
| Abrir caixas | 1 clique, custa 1 pancada |
| Arrastar e soltar | Peças nas cartas (troca no lugar ocupado); botão direito vende; Freak inteiro troca de carta ou vai para VENDER |
| Visual composto | Ímãs unem as 6 partes pelas esferas de metal (frente e perfil; tronco tem 5 ímãs) |
| Incluir Freak | Folha 6+6 vira 12 peças 200×200 + fichas (menu Tools ou script); ímãs se marcam arrastando bolinhas |
| Fundo de arena | Respiração de vinheta + partículas de poeira (mais escuro na luta) |
| Áudio | Efeitos: martelo, caixa, peças, impacto da luta |
| Export Web | Scripts `tools/export_web.ps1` + `tools/serve_web.ps1` (localhost) |
| Dados | **Leão** na loja (6 peças nível 1). Outros Freaks desligados neste teste |
| Scripts de verificação | Rodam checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| Arte no padrão `-1/-2` | Frente / perfil por peça, arquivos **200×200**. Golpe (`-3`) é opcional |
| ThemeTokens | Cores iguais às da Unity (ouro, creme, vermelho do PRONTO) |
| IA dos bots | Completa set, preenche carta, só troca se a carta ficar mais forte, sobe nível com calma |

## Ainda não existe

- Multiplayer
- Habilidade de set completo
- Freeze por caixa (hoje trava a prateleira inteira)
- Áudio de música de fundo / menu de volume
- Menus / navegação entre telas
- Salvamento / progressão
- Controles de gamepad

## Motor e entrada

- **Godot 4.7**, renderer Forward Plus
- Cena principal: `scenes/assembly/Assembly.tscn`
