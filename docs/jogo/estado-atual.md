# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (MVP do auto-battle contra bots)

| Área | Situação |
|------|----------|
| Partida contra 3 bots | 4 vivos, HP 40, último de pé ganha |
| Preparação | Até 60 s ou botão PRONTO |
| Loja | 5 caixas, pancadas, atualizar, travar, vender, subir nível |
| Montagem | 3 cartas (3º / 2º / 1º), misturar peças, carta incompleta vale |
| Luta em fila | Choque parte contra parte, cópia das cartas, teto de 12 de dano por Freak |
| Tela de luta | Palco no shelf, tags coloridas, colisão no centro, cartas sobem e somem |
| Abrir caixas | 2 cliques, custa 1 pancada |
| Arrastar e soltar | Peças nas cartas; Freak inteiro troca de carta ou vai para VENDER |
| Visual composto | Ímãs unem cabeça / tronco / pernas |
| Fundo de arena | Respiração de vinheta + partículas de poeira |
| Áudio | Efeitos: martelo, caixa, peças, impacto da luta |
| Export Web | Scripts `tools/export_web.ps1` + `tools/serve_web.ps1` (localhost) |
| Dados | Vampiro, Policial e Bruxa (um número de combate por peça) |
| Scripts de verificação | Rodam checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| Arte no padrão `-1/-2/-3` | Frente / perfil / ataque por peça |
| ThemeTokens | Cores da UI (PREP laranja, tags, pancadas) já usadas na tela nova |
| IA dos bots | Simples: completar set, preencher carta, atualizar ou subir nível |

## Ainda não existe

- Multiplayer
- Cachorro / Múmia (sem desenho ainda)
- Habilidade de set completo
- Freeze por caixa (hoje trava a prateleira inteira)
- Áudio de música de fundo / menu de volume
- Menus / navegação entre telas
- Salvamento / progressão
- Controles de gamepad

## Motor e entrada

- **Godot 4.7**, renderer Forward Plus
- Cena principal: `scenes/assembly/Assembly.tscn`
