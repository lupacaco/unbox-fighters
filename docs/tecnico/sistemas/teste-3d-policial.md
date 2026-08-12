# Teste 3D — policial (montagem completa)

Cópia da **tela de montagem** (caixas, 3 cartas, arrastar, LUTAR), com **só o policial**, e as peças em **3D**.

A tela 2D principal **não muda**. Isto é uma cena à parte.

**Não precisa de um projeto 3D novo.** O Godot já mistura 2D e 3D no mesmo projeto. O Unity deste teste também continua no projeto 2D: o boneco 3D é fotografado numa “salinha” escondida e colado na tela 2D.

## O que é igual ao jogo

- Fundo, prateleira, 3 cartas em branco
- Abrir caixa com 2 cliques
- Arrastar cabeça / tronco / pernas para a carta
- Nome, BRN / PWR / SPD, botão LUTAR
- LUTAR: pula na prateleira, anda até o meio, lança cada parte e volta

## O que muda

- Só 3 caixas (cabeça, tronco e pernas do policial)
- Na carta e na luta, a peça é o **modelo 3D**, não a figura 2D
- Ao virar de perfil, o modelo **gira** (não troca de desenho)
- No ataque, a **parte 3D** voa para a frente e volta

## Por que ficou preto / recortado (e o que foi corrigido)

Os arquivos `.glb` têm a pintura (textura), mas:

1. **O material veio como “metal”.** No formato glTF, se o arquivo não diz o contrário, o programa assume metal. Metal sem um céu/reflexo ao redor aparece **preto**. No Godot isso virou silhueta.
2. **O modelo não traz as “normais”.** Normais são setas invisíveis que dizem à luz qual lado é a frente de cada superfície. Sem isso, a luz não pinta direito.
3. **No Unity a câmera 2D atravessava o boneco.** A tela 2D trata 1 pixel como 1 metro. O modelo foi esticado ~150 vezes, ficou enorme, e a câmera ficou **dentro** dele. Por isso a imagem saía recortada, oca e com farpas.

Correção: o jogo agora **usa a pintura direto** (sem depender de luz de metal) e, no Unity, **fotografa** o modelo em tamanho real numa câmera 3D pequena, em vez de esticar o boneco na tela 2D.

O teste também ficou mais leve: a foto 3D é menor e não usa o efeito extra de suavização que pesava o computador.

## Como abrir no Godot

1. Abra o projeto Godot (`unbox-fighters`)
2. Vá em `scenes/assembly3d/`
3. Dois cliques em **Assembly3D.tscn**
4. Aperte **F6** (cena atual) — **não** F5 (F5 abre o jogo 2D)

## Como abrir no Unity

1. Com o Unity aberto em `unbox-fighters-unity`
2. Menu: **Unbox Fighters → Bootstrap 3D Assembly (policial)** (só precisa de novo se a cena 3D não existir)
3. Play na cena `Assets/Scenes/Assembly3D.unity`
4. Aba Game em **1920×1080**, Scale **1x**

## Arquivos

**Godot:** `scenes/assembly3d/`, `scripts/assembly3d/`  
**Unity:** `Assets/Scripts/Assembly3D/`, cena `Assembly3D.unity`  
**Modelos:** `assets/characters/policial/3d/` (Godot) e `Assets/Art/Characters/policial/3d/` (Unity)
