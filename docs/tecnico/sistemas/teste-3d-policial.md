# Teste 3D — policial em GLB

Experimento para comparar **sprites 2D** (trocar frente/perfil) com **modelos 3D** (girar o personagem de verdade).

## O que é

Uma tela **só de teste**, parecida com a montagem, mas:

- 1 carta só (policial)
- cabeça + tronco + pernas vêm de arquivos **GLB** (modelo 3D)
- ao clicar **LUTAR**: pula na prateleira, **vira para a direita em 3D**, anda com pulinhos, ataca com as partes 3D e volta

Não substitui a tela principal do jogo. É para você ver e decidir.

## Como abrir no Godot

1. Abra o projeto `C:\dev\unbox-fighters` no Godot
2. No painel de arquivos, vá em `scenes/assembly/`
3. Dê dois cliques em **Assembly3DTest.tscn**
4. Aperte **Play** (F5 nesta cena, ou botão Play com esta cena aberta)

Arquivos 3D: `assets/characters/policial/3d/`

## Como abrir no Unity

1. Abra `C:\dev\unbox-fighters-unity` no Unity
2. No menu: **Unbox Fighters → Bootstrap 3D Test Scene**  
   (isso importa os GLB e cria/abre a cena)
3. A cena fica em `Assets/Scenes/Assembly3DTest.unity`
4. Aperte **Play**
5. Na aba **Game**, use resolução **1920×1080** e Scale **1x**

Os GLB estão em `Assets/Art/Characters/policial/3d/`.  
O Unity precisa do pacote **glTFast** (já listado no `Packages/manifest.json`) para ler GLB.

## Fica mais pesado?

**Um pouco sim**, neste teste:

| | 2D (sprites) | 3D (estes GLBs) |
|--|--------------|-----------------|
| Arquivos do policial | várias PNGs leves | ~4,5 MB de GLB + texturas |
| Detalhe na tela | 3 imagens empilhadas | ~41 mil pontos do modelo (bem denso) |
| Virar de perfil | troca a figura | gira o objeto de verdade |
| Andar / atacar | troca poses `-2`/`-3` | movimento + inclinação (ainda sem animação de ossos) |

No PC, para **um** lutador, costuma rodar bem.  
Se no futuro forem **muitos** lutadores 3D densos assim (celular / web), aí pesa mais que 2D.

## Como funciona (ideia simples)

- No 2D atual: cada “pose” é uma **foto** diferente (frente, perfil, ataque).
- No 3D: é um **boneco** de verdade. A câmera olha de frente; para “perfil”, o boneco **gira**.
- Estes GLBs **não têm animação** gravada. O pulo/caminhada/ataque deste teste são movimentos feitos no código (não é mocap / skeleton ainda).

## Arquivos principais

**Godot**

- `scenes/assembly/Assembly3DTest.tscn`
- `scripts/assembly/assembly_3d_test_controller.gd`
- `scripts/assembly/fighter_3d_puppet.gd`

**Unity**

- `Assets/Scenes/Assembly3DTest.unity` (criada pelo Bootstrap 3D)
- `Assets/Scripts/Assembly3D/`

## Decisão de produto (ainda aberta)

Este teste serve para sentir:

- se o visual 3D vale a pena no estilo do jogo
- se o peso e o trabalho (arte + encaixe das partes) compensam

A tela principal continua sendo a montagem **2D** até você decidir o contrário.
