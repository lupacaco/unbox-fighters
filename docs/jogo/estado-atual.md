# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (MVP do auto-battle contra bots)

| Área | Situação |
|------|----------|
| Partida contra 3 bots | 4 vivos, HP 40, último de pé ganha. Bots: Sombra, Ferrugem, Névoa |
| Preparação | Até 60 s (relógio `1:00`) ou botão PRONTO |
| Loja | 5 caixas coladas nos rolos; NÍVEL/ATUALIZAR à esquerda, TRAVAR/VENDER à direita, pancadas douradas no topo |
| Montagem | 3 cartas (3º / 2º / 1º), misturar peças, carta incompleta vale |
| Luta em fila | Choque de kits sorteados (pode misturar cabeça vs braço), só o vencedor ataca, empate os dois atacam no centro, cópia das cartas, teto de 12 de dano por Freak |
| Tela de luta | Um contra um na esteira: pulo na mola, dois pulos até o ataque (base sai do chão junto, sombra + recorte nos rolos), o kit vencedor voa até a peça do outro (empate: os dois batem no centro), KO. Nomes/HP/VS ficam inteiros no topo. Peça destruída voa para fora da tela. Cobertura: frente (cabeça, braço E, braço D, tronco, mola) e perfil (braço D, tronco, cabeça, braço E, mola) |
| Fim de partida | **Você venceu!** / **Você saiu** e botão **NOVA PARTIDA** |
| Abrir caixas | 1 clique, custa 1 pancada |
| Arrastar e soltar | Peças nas cartas (troca no lugar ocupado); botão direito vende; Freak inteiro troca de carta ou vai para VENDER. Sem retângulo vermelho: a carta acende ouro |
| Visual composto | Base-mola em toda carta (menor que as peças e mais baixa no quadro; solta vazia, pressionada com peça). Sem placa de nome embaixo. Ímãs unem cabeça e tronco pelas esferas; cada braço cola no ombro. Na frente os braços abrem um pouco |
| Interface | Fontes de jogo, botões com borda ouro, loja nas laterais (não em cima da esteira) |
| Incluir Freak | Folha 4+4 vira 8 PNG 200×200 + 4 kits na loja; ímãs em janela compacta (Ampliar para precisão). A mola já está na carta |
| Fundo de arena | Respiração de vinheta + partículas de poeira. Fundo e esteira não mudam na luta |
| Áudio | Efeitos gravados (martelo, caixa, ímã). Na luta: boing de mola de desenho no impulso, passo no pouso e poom do golpe |
| Export Web | Scripts `tools/export_web.ps1` + `tools/serve_web.ps1` (localhost) |
| Dados | Loja lê sozinha todo `*_character.tres` (Vampiro, Bruxa) |
| Scripts de verificação | Rodam checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| Arte no padrão `-1/-2` | Frente / perfil por desenho, arquivos **200×200**. Sem pose de golpe (`-3`): o ataque arremessa o kit |
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
