# Múmia 3D no shelf (preview)

Cena de teste: **só a prateleira** e a múmia montada (cabeça + tronco + pernas em 3D).  
**Não** é a tela de montagem oficial. Essa continua em `scenes/assembly/Assembly.tscn`.

## Como ver

1. Abra o projeto no Godot 4.7
2. Abra `scenes/preview/MumiaShelfPreview.tscn`
3. Aperte **F6**
4. Clique em **INICIAR**

## O que acontece ao clicar

1. A múmia aparece de frente no canto esquerdo do shelf.
2. Vira de perfil para a direita e anda até o meio.
3. Dá socos, um chute e mexe a cabeça.
4. Anda até o fim do shelf, dá meia-volta e volta pulando para o início.

## Os arquivos originais

Os `.glb` em `C:\dev\3D\mumia-3d` eram só o modelo parado: forma 3D + textura, **sem ossos**.  
Sem ossos o joelho, o braço e o pescoço não dobram de verdade.

O script `tools/rig_mumia_parts.py` cria os ossos e grava as animações `idle`, `walk`, `punch`, `kick`, `jump` e `look`.

## Limite

O modelo não veio preparado para animar. O movimento funciona, mas o tecido pode esticar um pouco nas juntas.

## Como gerar de novo

```
python tools/rig_mumia_parts.py
```

## Arquivos

| Arquivo | Função |
|---------|--------|
| `tools/rig_mumia_parts.py` | Cria ossos e animações das 3 peças |
| `tools/glb_rig_lib.py` | Funções compartilhadas para gravar o GLB com esqueleto |
| `assets/characters/mumia/3d/` | Modelos originais e versões com ossos |
| `scenes/preview/MumiaShelfPreview.tscn` | Tela do shelf + botão INICIAR |
| `scripts/preview/mumia_shelf_preview.gd` | Sequência ao clicar |
| `scripts/preview/mumia_fighter_3d.gd` | Junta as 3 peças 3D e mostra no shelf |
| `scripts/core/verify_mumia_shelf.gd` | Confere animações e a cena |
