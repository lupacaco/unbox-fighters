# Sistema: áudio (efeitos sonoros)

Sons curtos que tocam nas ações do jogador.

## Como funciona

Há um **autoload** chamado `Sfx` (fica sempre disponível no jogo).  
Autoload = um script que o Godot liga sozinho ao iniciar, para qualquer cena poder usar.

O jogo chama os sons por `GameAudio` (`scripts/audio/game_audio.gd`), que encaminha para o `Sfx`.

Arquivo do player: `scripts/audio/sfx.gd`  
Sons: `assets/audio/sfx/*.wav` (gravações, não bipes de script)

Ele usa um **pool** de 12 players (reaproveita canais) para vários sons ao mesmo tempo sem travar.  
Pool = um grupo de “caixas de som” prontas; o jogo pega a próxima livre.

Os efeitos passam por um canal **SFX** com compressão leve (segura o volume quando martelo e caixa tocam juntos) e um teto para não estourar.

## Sons atuais

| ID | Arquivo | Quando toca |
|----|---------|-------------|
| `hammer_hit` | `hammer_hit.wav` | Martelo na caixa (junto com o estouro) |
| `crate_crack` | `crate_crack.wav` | Trinca de madeira (reservado) |
| `crate_break` | `crate_break.wav` | Caixa quebra / tábuas caindo |
| `part_pickup` | `part_pickup.wav` | Começa a arrastar uma peça |
| `part_place` | `part_place.wav` | Peça encaixa na carta |
| `part_reject` | `part_reject.wav` | Soltou no lugar errado / voltou / sem pancada |
| `fighter_complete` | `fighter_complete.wav` | Carta completa (3 kits) e vitória no palco |
| `impact` | `impact.wav` | Soco / chute / cabeçada no choque |
| `whoosh` | `whoosh.wav` | Pulo e avanço no palco |
| `land` | `land.wav` | Pouso no chão da prateleira |
| `step` | `step.wav` | Passo ao andar na luta |

Abrir a caixa toca martelo e, um instante depois, a madeira quebrando — os dois juntos, sem o mesmo arquivo servindo para tudo.

Origem e licença: [assets/audio/sfx/ATTRIBUTION.md](../../assets/audio/sfx/ATTRIBUTION.md).

## Gerar de novo

```bash
python tools/fetch_sfx.py
```

(Precisa de `miniaudio` e `numpy` no Python.) Isso baixa de novo as gravações da Mixkit e recorta/normaliza. Não use o gerador antigo de bipes.

## Ainda não existe

- Música de fundo
- Volume configurável na tela
- Sons de UI genéricos (botões de menu)
