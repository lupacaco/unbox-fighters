# Sistema: tela de montagem

A cena principal do jogo hoje: preparação + loja + luta no mesmo palco.

## Arquivos

| Tipo | Caminho |
|------|---------|
| Cena | `scenes/assembly/Assembly.tscn` |
| Controlador | `scripts/assembly/assembly_controller.gd` (`AssemblyController`) |
| Cenas filhas | `CharacterSlot.tscn`, `Crate.tscn`, `PartView.tscn` |

## O que o controlador faz ao iniciar

1. Liga o arraste (peça, carta, vender)
2. Carrega o elenco (vampiro, policial, bruxa)
3. Sobe o HUD: **PREP.**, HP, PRONTO, barra da loja
4. Liga as **3 cartas** (3º / 2º / 1º)
5. Começa a partida (`MatchState`) e sorteia **5 caixas**
6. Os 3 bots compram na hora

## Layout aproximado

- Cartas em X ≈ 380, 960, 1540; Y ≈ 400 — etiquetas 3º, 2º, 1º (1º à direita)
- Prateleira / palco em torno de Y ≈ 920
- 5 caixas; área **VENDER** à esquerda da prateleira
- HUD: PREP. no canto, HP no topo, NÍVEL / PANCADAS / ATUALIZAR / TRAVAR embaixo

## Loja

Ofertas vêm do nível da loja (e abaixo). Quebrar caixa gasta 1 pancada.

## Relação com outras cenas

- `Crate` — 2 cliques → some → instancia `PartView`  
- `CharacterSlot` — recebe peças; o rótulo da fila arrasta o Freak inteiro  
- `FightDirector` — palco da luta
