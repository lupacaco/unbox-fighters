# Testes rápidos (headless)

Scripts que verificam partes do jogo **sem** você jogar na tela.  
“Headless” = roda o Godot sem a janela completa de jogo, só para checar.

## Onde ficam

`scripts/core/`

| Script | O que verifica |
|--------|----------------|
| `verify_synergy.gd` | 100/75/50 no modelo de 3 kits, números do leão, curva de pancadas |
| `verify_combat_sim.gd` | Choque, empate, teto de 12 de dano no HP |
| `verify_shop_pool.gd` | Loja vende todo Freak com ficha; tronco do médico só no nível 2; 5 ofertas |
| `verify_character_importer.gd` | Id `Leão` → `leao`; cada Freak com 12 desenhos; folha do médico vira 6+6 |
| `verify_match_state.gd` | 4 vivos, HP 40, nomes dos bots, oponente-fantasma |
| `verify_assembly.gd` | 3 cartas, 5 caixas e VENDER à direita |
| `verify_crate_open.gd` | Um clique na caixa solta a peça |
| `verify_composite.gd` | Layout por ímãs (6 desenhos) e expansor 3→6 |
| `verify_part_magnets.gd` | Cabeça só embaixo; tronco com 5 ímãs; virar X; Z da cabeça na frente; imagem nova vira 200×200 |
| `verify_part_sizes.gd` | Sprites 200×200 e perfil nos 6 desenhos |
| `verify_fight_line.gd` | Fila no mesmo chão; perna e braço giram nos ímãs |
| `verify_fight_poses.gd` | Personagem tem perfil; carta aceita os 3 kits |
| `verify_fight_lock.gd` | Travamento da carta; soltar kit em lugar ocupado devolve o antigo |
| `debug_parts.gd` | Carrega peça e checa visibilidade do sprite |
| `debug_reveal.gd` | Força revelar peça da caixa e checa transparência |

## Quando atualizar

Se mudar a tela, a loja, a sinergia, a luta, as caixas ou a arte, revise estes scripts e este doc.
