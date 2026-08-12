# Teste 3D — cópia fiel da montagem (só policial)

Experimento: **mesma tela de montagem** (caixas, carta, arrastar/soltar, LUTAR), com **apenas o policial**, e as peças em **3D (GLB)**.

## O que deve acontecer

1. Abrir 3 caixas (cabeça / tronco / pernas do policial)
2. Arrastar para **1 carta**
3. Ver o policial montado em 3D na carta
4. Clicar **LUTAR**:
   - limpa a prateleira
   - pula para a esquerda do shelf
   - **gira em 3D** para o perfil (não troca sprite)
   - anda até o meio
   - lança cada **parte 3D** (bumerangue)
   - volta para a carta

A tela principal 2D (`Assembly.tscn`) **não muda**.

## Como abrir no Godot (importante)

1. Abra `scenes/assembly3d/Assembly3D.tscn` (dois cliques)
2. Rode com **F6** (Executar cena atual)  
   — **F5** abre a montagem 2D normal

## Pastas

| Item | Caminho |
|------|---------|
| Cena | `scenes/assembly3d/Assembly3D.tscn` |
| Scripts | `scripts/assembly3d/` |
| GLBs | `assets/characters/policial/3d/` |

## Unity

No projeto Unity: menu **Unbox Fighters → Bootstrap 3D Assembly**  
(cena `Assets/Scenes/Assembly3D.unity`). Use Game **1920×1080** / Scale **1x**.

## Peso

Um policial 3D detalhado é mais pesado que sprites 2D. Neste teste (1 lutador) no PC costuma ir bem.
