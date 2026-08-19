# Testes rápidos (headless)

Scripts que verificam partes do jogo **sem** você jogar na tela.  
“Headless” = roda o Godot sem a janela completa de jogo, só para checar.

## Onde ficam

`scripts/core/`

Rode todos de uma vez:

```
powershell -File tools/run_checks.ps1
```

| Script | O que verifica |
|--------|----------------|
| `verify_synergy.gd` | Tipo igual +50%; Bruxa 8→12 e 15→23; mistura lê FREAK; set completo lê BRUXA; verde/vermelho |
| `verify_duel.gd` | Golpes intercalados; o vencedor mata sozinho; preço; vender $1; atualizar $2 |
| `verify_belt.gd` | 5 remadas de 1 s até a ponta, braço para a frente e meia-lua para trás, fila de 3 com espaço entre os caixotes, 5 de dano por vivo |
| `verify_bot.gd` | O oponente gasta na preparação, não lança antes da luta, prefere fechar o set, não compra kit que não dá para emparelhar |
| `verify_shop_pool.gd` | Loja vende todo Freak com ficha; 2 kits por Freak; 4 ofertas |
| `verify_match_phases.gd` | Rodada vazia sem dano; 2 vivos causam 10; sobra de dinheiro + $10 |
| `verify_character_importer.gd` | Acentos viram id simples; folha da Bruxa vira 4+4; `_slice.json` tem ímãs |
| `verify_character_remover.gd` | Lista o elenco; apaga um Freak temporário por completo; não mexe na Bruxa |
| `verify_character_editor.gd` | Muda a ficha da Bruxa e devolve os arquivos; os ímãs ficam no mesmo lugar |
| `verify_assembly.gd` | 3 cartas no topo, caixote do mesmo tamanho vazio ou com peça, 4 prateleiras com kit visível, barras de vida, relógio, 2 esteiras, fundo, fontes, câmera parada |
| `verify_crate_open.gd` | A prateleira já mostra o kit com o preço, sem caixa para quebrar |
| `verify_composite.gd` | Caixote em duas partes no chão; tronco encaixa nele; cabeça no pescoço; corpo da loja traz os dois braços |
| `verify_part_magnets.gd` | Cabeça só embaixo; tronco com 4 ímãs; virar X; Z da carta e da luta |
| `verify_part_sizes.gd` | Sprites 200×200 e perfil nos desenhos visíveis |
| `verify_ability.gd` | Recurso salva em 1 HP uma vez; Controle de Mente desvia o golpe para o aliado |
| `import_roster.gd` | Não é teste: gera as fichas a partir dos `_slice.json` |
| `remove_character.gd` | Não é teste: apaga um Freak por id (`-- ID`) |
| `edit_character.gd` | Não é teste: mostra ou grava a ficha (`-- bruxa --attack 9`) |

## Quando atualizar

Se mudar a tela, a loja, a sinergia, a luta, as caixas ou a arte, revise estes scripts e este doc.
