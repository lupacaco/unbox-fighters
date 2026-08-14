# Sistema: áudio (efeitos sonoros)

Sons curtos que tocam nas ações do jogador.

## Como funciona

Há um **autoload** chamado `Sfx` (fica sempre disponível no jogo).  
Autoload = um script que o Godot liga sozinho ao iniciar, para qualquer cena poder usar.

O jogo chama os sons por `GameAudio` (`scripts/audio/game_audio.gd`), que encaminha para o `Sfx`.

Arquivo do player: `scripts/audio/sfx.gd`  
Sons: `assets/audio/sfx/*.wav`

Ele usa um **pool** de 8 players (reaproveita canais) para vários sons ao mesmo tempo sem travar.

## Sons atuais

| ID | Arquivo | Quando toca |
|----|---------|-------------|
| `hammer_hit` | `hammer_hit.wav` | Cada clique na caixa |
| `crate_crack` | `crate_crack.wav` | 1º clique (caixa trinca) |
| `crate_break` | `crate_break.wav` | 2º clique (caixa quebra) |
| `part_pickup` | `part_pickup.wav` | Começa a arrastar uma peça |
| `part_place` | `part_place.wav` | Peça encaixa na carta |
| `part_reject` | `part_reject.wav` | Soltou no lugar errado / voltou |
| `fighter_complete` | `fighter_complete.wav` | Carta completa (3 kits) e impacto do choque na luta |

## Gerar de novo

```bash
python tools/generate_sfx.py
```

Os WAVs atuais são gerados por esse script (efeitos simples). Depois podem ser trocados por arte sonora profissional sem mudar o código — basta manter os nomes dos arquivos.

## Ainda não existe

- Música de fundo
- Volume configurável na tela
- Sons de UI genéricos (botões de menu)
