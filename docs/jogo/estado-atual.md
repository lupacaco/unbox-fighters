# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (partida corrida 1 contra 1)

| Área | Situação |
|------|----------|
| Partida | 1 oponente, barra-balança 50-0-50, jogo corre sem relógio de rodada |
| Dinheiro | Começa em $10, +$1 a cada 2 s, teto $10. Substitui as pancadas |
| Loja | 1 prateleira no meio; atualizar grátis; VENDER pela metade |
| Montagem | 2 cartas suas à esquerda; 2 cartas vermelhas do oponente à direita |
| Esteiras | Azul sua, vermelha deles; pulo da carta; 5 remadas (2 s cada); oponente olha para a esquerda; etiquetas de Ataque e HP |
| Luta | Só a cabeça ataca; golpes um de cada vez; o vencedor dá o golpe final; morto cai no vão. Bruxa: Controle de Mente. Advogado: Recurso |
| Chip | Freak sozinho na ponta empurra a balança 1 ponto por segundo; 50 no lado dele vence |
| Visual | Fundo, cartas, prateleira e esteiras da arte nova (`assets/nova-ui`) |
| Arrastar e soltar | Da prateleira para as cartas azuis; clicar seleciona para vender; arrastar na lixeira também vende |
| Composição | Caixote compartilhado na carta e na esteira; tronco encaixa pelo ímã de baixo |
| Interface | Dinheiro ao lado da prateleira; botões redondos de atualizar e vender; barra-balança no topo (JOGADOR / OPONENTE) |
| Incluir Freak | Folha 4+4 vira 8 PNG 200×200 + 2 kits na loja; ímãs em Frente e Perfil |
| Editar Freak | **Projeto → Ferramentas → Editar personagem**: nome, tipo, Poder, Ataque e HP |
| Remover Freak | **Projeto → Ferramentas → Remover personagem**: escolhe na lista e apaga desenhos, pasta e fichas |
| Janelas das Ferramentas | Todas **800 × 600**, com barra para rolar se o conteúdo for maior |
| Áudio | Efeitos gravados (martelo, caixa, ímã, impacto). Sem som de mola |
| Dados | Loja lê sozinha todo `*_character.tres` (Bruxa, Advogado) |
| Bot | Compra, monta e manda lutar com as mesmas regras e o mesmo tempo de mãos |
| Scripts de verificação | 14 checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| Elenco | Só Bruxa (Sobrenatural) e Advogado (Humano). Ainda não tem Animal |
| Ritmo do dinheiro | Um Freak custa $12–13 e o teto é $10. Só jogando dá para acertar o tempo |
| Ímãs | O recorte já sugere os pontos; ainda vale conferir na ferramenta de ímãs |
| Arte no padrão `-1/-2` | Frente / perfil, arquivos **200×200**. Sem pose de golpe (`-3`) |

## Ainda não existe

- Multiplayer
- Áudio de música de fundo / menu de volume
- Menus / navegação entre telas
- Salvamento / progressão
- Controles de gamepad
- Botão de nova partida depois do fim (hoje o placar só anuncia quem ganhou)

## Motor e entrada

- **Godot 4.7**, renderer Forward Plus
- Cena principal: `scenes/assembly/Assembly.tscn`
