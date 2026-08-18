# Arquitetura

Como o programa está organizado por dentro (visão simples).

## Em uma frase

Há **uma tela principal**. As **regras da partida** (dinheiro, esteira, luta) ficam em código puro; a tela só **mostra** o que aconteceu.

## Camadas

```
Tela (cenas .tscn)
    ↓
Controladores / HUD (assembly + ui)
    ↓
Regras da partida (scripts/match)
    ↓
Dados (PartDef, CharacterDef, CompositeResolver)
    ↓
Arte e recursos (assets/, data/)
```

## Peças principais

| Peça | Papel |
|------|--------|
| `AssemblyController` | Maestro: loja, cartas, esteiras, animações |
| `LiveMatch` | Tempo correndo: dinheiro, esteira, duelo, fim da partida |
| `PlayerState` | Vida, carteira, loja e esteira de **um** lado (você ou o bot) |
| `BeltLane` | Até 2 Freaks deslizando até a ponta |
| `Duel` | Contas de um troca-troca de golpes |
| `FreakStats` / `Synergy` | Poder, Resistência e Agilidade já com o bônus |
| `ShopPool` / `BotBrain` | Sorteio da loja e o oponente jogando igual a você |
| `BeltFreak` / `FlyingHead` | Desenho do Freak na esteira e a cabeça que voa |
| `MoneyBar` / `ActionBar` / `PlayerHpBar` | Dinheiro, ATUALIZAR/VENDER, barras de vida |
| `DragDropService` | Arraste de peça, soltar na carta, vender |
| `Crate` / `PartView` / `CharacterSlot` / `ShopShelf` | Caixa, peça, carta, prateleira |
| `CompositeResolver` / `PartKit` | Cola cabeça, tronco e cada braço no caixote |

## Organização dos scripts

| Pasta | Responsabilidade |
|-------|------------------|
| `scripts/assembly/` | Tela: cartas, caixas, esteira visível |
| `scripts/match/` | Regras (podem ser testadas sem abrir o jogo) |
| `scripts/data/` | Definições de peças e composição visual |
| `scripts/ui/` | HUD, tags, cores |
| `scripts/core/` | Scripts de verificação e importar o elenco |

## Padrões usados

- **Dados em Resource** (`.tres`): fichas editáveis no Godot.
- **Cenas instanciadas**: carta, caixa, peça.
- **Sinais**: “loja sorteada”, “Freak lançado”, “golpes trocados”. Um sinal é um aviso de que algo aconteceu, sem a outra parte ficar perguntando o tempo todo.
- **Lógica pura** em `Duel` e `Synergy`: a animação não inventa o resultado.

## O que ainda não há na arquitetura

- Rede / multiplayer
- Troca de cenas (menu, etc.)

## Diagrama simples

```mermaid
flowchart TD
  AC[AssemblyController] --> LM[LiveMatch]
  AC --> Cards[2 cartas]
  AC --> Shop[4 prateleiras]
  LM --> PS[PlayerState x2]
  PS --> Lane[BeltLane]
  LM --> Bot[BotBrain]
  LM --> Duel[Duel]
  Syn[Synergy] --> Stats[FreakStats]
  Stats --> Lane
```
