# Godot MCP (assistente ligado ao editor)

MCP = ponte entre o Cursor e o Godot aberto (cenas, nós, play, erros, export).

## Opção escolhida (grátis)

**[KeeVeeG/godot-mcp](https://github.com/KeeVeeG/godot-mcp)** — MIT, grátis, testado com **Godot 4.7**, 300+ tools.

Por que esta:
- Gratuita
- Feita para Godot 4.7 (a nossa versão)
- Ligação ao editor ao vivo (não só arquivos)
- Setup simples no Cursor com `npx`

Alternativas que consideramos: Godot MCP Pro (pago) e [Godot AI](https://github.com/hi-godot/godot-ai) (também grátis).

## O que já está no projeto

1. Plugin em `addons/godot_mcp/` (ativo em `project.godot`)
2. Config Cursor: `.cursor/mcp.json`

## Como ativar (uma vez)

1. **Abra o projeto no Godot 4.7**
2. Confirme: **Projeto → Configurações do Projeto → Plugins → Godot MCP = Ativo**
3. **Reinicie o Cursor** (para ler o `.cursor/mcp.json`)
4. No Godot, olhe o painel **MCP** embaixo — deve mostrar conexão
5. No Cursor: Settings → MCP → servidor `godot` deve aparecer conectado

Com o Godot **aberto** e o plugin ativo, eu consigo usar as tools do MCP.

## Se não conectar

- Godot precisa estar aberto com este projeto
- Plugin ativo
- Cursor reiniciado depois do `mcp.json`
- Portas localhost 6505–6514 livres
- Node.js instalado (já está nesta máquina)

## Docs oficiais do addon

- Repo: https://github.com/KeeVeeG/godot-mcp  
- Catálogo de tools: https://nikita-abaturov.ru/godot-mcp/tools.html
