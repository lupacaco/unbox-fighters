# Teste 3D — policial (montagem completa)

Cópia da **tela de montagem** (caixas, 3 cartas, arrastar, LUTAR), com **só o policial**, e as peças em **3D**.

A tela 2D principal **não muda**. Isto é uma cena à parte.

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

## Como abrir no Godot

1. Abra o projeto Godot (`unbox-fighters`)
2. Vá em `scenes/assembly3d/`
3. Dois cliques em **Assembly3D.tscn**
4. Aperte **F6** (cena atual) — **não** F5 (F5 abre o jogo 2D)

## Como abrir no Unity

1. Com o Unity aberto em `unbox-fighters-unity`
2. Menu: **Unbox Fighters → Bootstrap 3D Assembly (policial)**
3. Play na cena `Assets/Scenes/Assembly3D.unity`
4. Aba Game em **1920×1080**, Scale **1x**

## Arquivos

**Godot:** `scenes/assembly3d/`, `scripts/assembly3d/`  
**Unity:** `Assets/Scripts/Assembly3D/`, cena `Assembly3D.unity`  
**Modelos:** `assets/characters/policial/3d/` (Godot) e `Assets/Art/Characters/policial/3d/` (Unity)
