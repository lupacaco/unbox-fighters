# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (partida em rodadas 1 contra 1)

| Área | Situação |
|------|----------|
| Partida | 1 oponente, duas telas por rodada (preparação 60s e luta), 50 de vida cada, 5 de dano por Freak vivo no fim da luta |
| Dinheiro | Começa em $10; sobra fica; +$10 no início de cada nova preparação; teto $50. Não sobe sozinho |
| Loja | 4 prateleiras 2×2 com a peça já visível; atualizar $2; VENDER $1 |
| Montagem | 3 cartas suas à esquerda; 3 cartas vermelhas do oponente só na luta |
| Esteiras | Azul sua, vermelha deles; param nos rolos (não no buraco); até 3 Freaks com vão entre os caixotes |
| Luta | Só a cabeça ataca; golpes um de cada vez; o vencedor dá o golpe final; nocaute na esteira e volta para a carta. Bruxa: Controle de Mente. Advogado: Recurso |
| Visual | Fundo, cartas, prateleira e esteiras da arte nova (`assets/nova-ui`) |
| Arrastar e soltar | Da prateleira para as cartas azuis (pagar no soltar); clicar seleciona para vender; arrastar na lixeira também vende |
| Composição | Caixote um pouco maior, em duas partes; nome, Ataque e HP só no retângulo preto; na esteira o braço fica para a frente e por cima dos números |
| Interface | Dinheiro em círculo $N; botões redondos de atualizar e vender; barras de vida acima das esteiras; relógio 60s; LUTAR AGORA |
| Incluir Freak | Folha 4+4 vira 8 PNG 200×200 + 2 kits na loja; ímãs em Frente e Perfil |
| Editar Freak | **Projeto → Ferramentas → Editar personagem**: nome, tipo, Poder, Ataque e HP |
| Remover Freak | **Projeto → Ferramentas → Remover personagem**: escolhe na lista e apaga desenhos, pasta e fichas |
| Janelas das Ferramentas | Todas **800 × 600**, com barra para rolar se o conteúdo for maior |
| Áudio | Efeitos gravados (martelo, caixa, ímã, impacto). Sem som de mola |
| Dados | Loja lê sozinha todo `*_character.tres` (Bruxa, Advogado) |
| Bot | Compra e monta no mesmo relógio de 60s; na luta os PRONTO dele também pulam |
| Scripts de verificação | Checagens sem abrir a interface completa, inclusive as fases da rodada |

## Parcial / provisório

| Item | Observação |
|------|----------|
| Elenco | Só Bruxa (Sobrenatural) e Advogado (Humano). Ainda não tem Animal |
| Ritmo do dinheiro | Um Freak nomeado custa $12–13 e a rodada dá $10. Dá para juntar sobra entre rodadas |
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
