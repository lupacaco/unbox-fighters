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
| `verify_synergy.gd` | Dupla +25% / tripla +50%; Bruxa 8→10 e 8→12; carta mista |
| `verify_duel.gd` | Os dois golpes entram; preço; dinheiro sobe a cada 2 s |
| `verify_belt.gd` | Deslize até a ponta, fila de 2, chip sozinho vence a partida |
| `verify_bot.gd` | O oponente gasta, manda Freak e prefere fechar o set |
| `verify_shop_pool.gd` | Loja vende todo Freak com ficha; 3 kits por Freak; 4 ofertas |
| `verify_character_importer.gd` | Acentos viram id simples; folha da Bruxa vira 4+4; `_slice.json` tem ímãs |
| `verify_assembly.gd` | 2 cartas, 4 prateleiras, 2 esteiras, fundo, fontes, câmera parada |
| `verify_crate_open.gd` | Pagar a caixa deixa o kit na prateleira pelo preço certo |
| `verify_composite.gd` | Caixote no chão; cabeça no pescoço; kit de braços vira dois |
| `verify_part_magnets.gd` | Cabeça só embaixo; tronco com 4 ímãs; virar X; Z da carta e da luta |
| `verify_part_sizes.gd` | Sprites 200×200 e perfil nos desenhos visíveis |
| `import_roster.gd` | Não é teste: gera as fichas a partir dos `_slice.json` |

## Quando atualizar

Se mudar a tela, a loja, a sinergia, a luta, as caixas ou a arte, revise estes scripts e este doc.
