# Testes rápidos (headless)

Scripts que verificam partes do jogo **sem** você jogar na tela.  
“Headless” = roda o Godot sem a janela completa de jogo, só para checar.

## Onde ficam

`scripts/core/`

| Script | O que verifica |
|--------|----------------|
| `verify_synergy.gd` | 2 iguais = 100% / 1 = 50%, números do vampiro, curva de pancadas |
| `verify_combat_sim.gd` | Choque, empate, teto de 12 de dano no HP, pares sorteados (pode misturar kits) |
| `verify_shop_pool.gd` | Loja vende todo Freak com ficha; 4 kits por Freak; 5 ofertas |
| `verify_character_importer.gd` | Acentos viram id simples (`Leão` → `leao`); cada Freak com 8 desenhos; folha do vampiro vira 4+4 |
| `verify_match_state.gd` | 4 vivos, HP 40, nomes dos bots, oponente-fantasma |
| `verify_assembly.gd` | 3 cartas, 5 caixas coladas nos rolos, loja acima da esteira, fontes, câmera parada, VENDER à direita, esteira no rodapé em 1920 |
| `verify_crate_open.gd` | Um clique na caixa solta a peça colada nos rolos |
| `verify_composite.gd` | Layout na mola (carta vazia solta; peça pressiona; cabeça na esfera) |
| `verify_part_magnets.gd` | Cabeça só embaixo; tronco com 5 ímãs; virar X; Z da cabeça na frente na carta; Z da luta frente e perfil; imagem nova vira 200×200 |
| `verify_part_sizes.gd` | Sprites 200×200 e perfil nos desenhos visíveis |
| `verify_fight_line.gd` | Fila no mesmo chão; disco da mola nos rolos da esteira; pulo da mola inteira; dois pulos até o ataque; sombra e recorte nos rolos; um boing ao sair do chão; duelistas afastados; placas de HP cabem no topo |
| `verify_thrown_kit.gd` | Kit copiado do boneco some do corpo e pode voltar |
| `verify_fight_poses.gd` | Personagem tem perfil; carta mostra a mola e a sombra; aceita cabeça, tronco e braços, recusa pernas |
| `verify_fight_lock.gd` | Travamento da carta; soltar kit em lugar ocupado devolve o antigo |
| `debug_parts.gd` | Carrega peça e checa visibilidade do sprite |
| `debug_reveal.gd` | Força revelar peça da caixa e checa transparência |

## Quando atualizar

Se mudar a tela, a loja, a sinergia, a luta, as caixas ou a arte, revise estes scripts e este doc.
