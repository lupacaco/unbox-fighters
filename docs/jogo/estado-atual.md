# Estado atual do projeto

Última revisão baseada no código existente. Atualize este arquivo sempre que o escopo mudar.

## Pronto (partida corrida 1 contra 1)

| Área | Situação |
|------|----------|
| Partida | 1 oponente, 100 de vida cada, jogo corre sem relógio de rodada |
| Dinheiro | Começa em $10, +$1 a cada 2 s, teto $10. Substitui as pancadas |
| Loja | 4 prateleiras com preço na caixa; ATUALIZAR $1; VENDER pela metade |
| Montagem | 2 cartas; só Freak completo (3 kits) vai para a esteira |
| Esteiras | Azul sua, vermelha deles; pulo da carta; 5 remadas (ritmo pela Agilidade); oponente olha para a esquerda; etiquetas de Poder e Resistência |
| Luta | Só a cabeça ataca; golpes um de cada vez; o vencedor dá o golpe final; morto cai no vão |
| Chip | Freak sozinho na ponta tira 1 de vida por segundo do outro jogador |
| Visual | Fundo, cartas, prateleiras e esteiras da arte nova (`assets/nova-ui`) |
| Arrastar e soltar | Da prateleira para a carta; clicar seleciona para vender; arrastar em VENDER também vende |
| Composição | Caixote do tronco é o chão. Ímãs unem cabeça no pescoço e braços nos ombros |
| Interface | Barra de dinheiro em tijolinhos, barras de vida em cima, botões ATUALIZAR / VENDER |
| Incluir Freak | Folha 4+4 vira 8 PNG 200×200 + 3 kits na loja; ímãs em Frente e Perfil |
| Áudio | Efeitos gravados (martelo, caixa, ímã, impacto). Sem som de mola |
| Dados | Loja lê sozinha todo `*_character.tres` (Bruxa, Advogado) |
| Bot | Compra, monta e manda lutar com as mesmas regras |
| Scripts de verificação | 11 checagens sem abrir a interface completa |

## Parcial / provisório

| Item | Observação |
|------|------------|
| Elenco | Só Bruxa e Advogado. Com 2 Freaks a sinergia quase sempre acontece |
| Ritmo do dinheiro | Um Freak custa $15–17 e o teto é $10. Só jogando dá para acertar o tempo |
| Ímãs | O recorte já sugere os pontos; ainda vale conferir na ferramenta de ímãs |
| Arte no padrão `-1/-2` | Frente / perfil, arquivos **200×200**. Sem pose de golpe (`-3`) |

## Ainda não existe

- Multiplayer
- Habilidade extra de set completo (além da sinergia)
- Áudio de música de fundo / menu de volume
- Menus / navegação entre telas
- Salvamento / progressão
- Controles de gamepad
- Botão de nova partida depois do fim (hoje o placar só anuncia quem ganhou)

## Motor e entrada

- **Godot 4.7**, renderer Forward Plus
- Cena principal: `scenes/assembly/Assembly.tscn`
