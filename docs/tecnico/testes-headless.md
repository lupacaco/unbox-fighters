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
| `verify_synergy.gd` | Tipo igual +50%; Bruxa 8→12 e 15→23; mistura Bruxa+Advogado sem bônus nem Poder |
| `verify_duel.gd` | Golpes intercalados; o vencedor mata sozinho; preço; dinheiro; atualizar grátis |
| `verify_belt.gd` | 5 remadas de 2 s até a ponta, fila de 2, 50 de chip a partir do 0 vence |
| `verify_bot.gd` | O oponente gasta, não lança no primeiro segundo, manda Freak e prefere fechar o set |
| `verify_shop_pool.gd` | Loja vende todo Freak com ficha; 2 kits por Freak; 1 oferta |
| `verify_character_importer.gd` | Acentos viram id simples; folha da Bruxa vira 4+4; `_slice.json` tem ímãs |
| `verify_character_remover.gd` | Lista o elenco; apaga um Freak temporário por completo; não mexe na Bruxa |
| `verify_assembly.gd` | 2+2 cartas no topo, 1 prateleira, barra-balança no topo (JOGADOR / OPONENTE), 2 esteiras, fundo, fontes, câmera parada |
| `verify_crate_open.gd` | Pagar a caixa deixa o kit na prateleira pelo preço certo |
| `verify_composite.gd` | Caixote no chão; tronco encaixa nele; cabeça no pescoço; corpo da loja traz os dois braços |
| `verify_part_magnets.gd` | Cabeça só embaixo; tronco com 4 ímãs; virar X; Z da carta e da luta |
| `verify_part_sizes.gd` | Sprites 200×200 e perfil nos desenhos visíveis |
| `verify_ability.gd` | Recurso salva em 1 HP uma vez; Controle de Mente desvia o golpe para o aliado |
| `import_roster.gd` | Não é teste: gera as fichas a partir dos `_slice.json` |
| `remove_character.gd` | Não é teste: apaga um Freak por id (`-- ID`) |

## Quando atualizar

Se mudar a tela, a loja, a sinergia, a luta, as caixas ou a arte, revise estes scripts e este doc.
