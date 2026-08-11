# Plataformas — Web, Steam e Google Play

O jogo vai existir em **mais de um lugar**. Cada lugar precisa de uma “versão empacotada” diferente.

## Visão geral

| Onde | Formato | Status hoje |
|------|---------|-------------|
| Navegador (localhost / site) | Export **Web** (HTML + WebAssembly) | **Pronto para testar** |
| Steam (PC) | Export Windows (depois Linux/Mac) | Futuro |
| Google Play (Android) | Export Android (`.aab`) | Futuro |

Templates do Godot **4.7.1** já foram instalados nesta máquina (inclui Web, Windows e Android).

---

## Navegador (agora)

### 1) Gerar a versão web

No PowerShell, na pasta do projeto:

```powershell
powershell -File tools/export_web.ps1
```

Isso cria `builds/web/index.html` (e arquivos vizinhos).

### 2) Rodar em localhost

```powershell
powershell -File tools/serve_web.ps1
```

Abra no Chrome/Edge: **http://localhost:8080**

Localhost = o jogo rodando no **seu** computador, como se fosse um site.

### Observações web

- Não abra o `index.html` direto no Explorer — use o servidor local.
- Threads desligadas no preset (mais compatível com navegadores).
- Sons e mouse devem funcionar; performance pode variar por PC/celular.

Preset: `export_presets.cfg` → nome **Web**.

---

## Steam (depois)

Resumo do caminho:

1. Conta de desenvolvedor Steamworks  
2. Export **Windows Desktop** do Godot  
3. Upload pelo SteamPipe  
4. Página da loja, builds, testes  

Ainda não está configurado no projeto.

---

## Google Play (depois)

Resumo do caminho:

1. Conta Google Play Console  
2. JDK + Android SDK no PC  
3. Export Android (`.aab`) no Godot  
4. Assinatura do app e envio na loja  

Templates Android já vieram no pacote do Godot; falta configurar SDK/keystore depois.

---

## Ordem recomendada

1. **Web** (testar rápido no navegador) ← estamos aqui  
2. **Windows/Steam** (versão PC)  
3. **Android/Play** (celular)
