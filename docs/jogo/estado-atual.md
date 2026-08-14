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
| Tela de luta | Um contra um no palco: pulo, andar até perto, choque, KO. Ordem de frente: cabeça, braço D, tronco, perna D, perna E, braço E |
| Fim de partida | **Você venceu!** / **Você saiu** e botão **NOVA PARTIDA** |
| Abrir caixas | 1 clique, custa 1 pancada |
| Arrastar e soltar | Peças nas cartas (troca no lugar ocupado); botão direito vende; Freak inteiro troca de carta ou vai para VENDER. Sem retângulo vermelho: a carta acende ouro |
| Visual composto | Ímãs unem os 6 desenhos pelas esferas de metal (frente e perfil; tronco tem 5 ímãs) |
| Incluir Freak | Folha 6+6 vira 12 PNG 200×200 + 3 fichas na loja; ímãs em janela compacta (Ampliar para precisão) |
| Fundo de arena | Respiração de vinheta + partículas de poeira (mais escuro na luta) |
| Áudio | Efeitos gravados (martelo, caixa, ímã, soco, passo, whoosh). Sem bipes de script |
| Export Web | Scripts `tools/export_web.ps1` + `tools/serve_web.ps1` (localhost) |
| Dados | **Leão** e **Médico** na loja (únicos Freaks no jogo agora) |
| Scripts de verificação | Rodam checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| Arte no padrão `-1/-2` | Frente / perfil por desenho, arquivos **200×200**. Sem pose de golpe (`-3`): o ataque mexe os membros |
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
