# Configuración de MCP para Blender y Godot

El **MCP** (Model Context Protocol) permite que un agente de IA (Claude Code, Codex, Cursor, etc.) controle Blender y Godot: ejecutar scripts, ver la escena, crear escenas, correr el juego y leer errores.

| App | Servidor MCP | Requisitos |
|---|---|---|
| Blender | [`mcp-for-blender`](https://github.com/ahujasid/mcp-for-blender) | `uv` + addon dentro de Blender |
| Godot | [`@coding-solo/godot-mcp`](https://github.com/Coding-Solo/godot-mcp) | Node.js 18 o superior |

Versiones usadas en el proyecto: **Blender 5.3** y **Godot 4.7**.

---

## 1. Requisitos previos

### macOS

```bash
brew install uv node
```

### Windows (PowerShell)

```powershell
winget install --id=astral-sh.uv -e
winget install OpenJS.NodeJS.LTS
```

Comprueba que estén instalados: `uvx --version` y `node --version`.

### Rutas de las aplicaciones

Necesitas la ruta del **ejecutable** de Godot. Ejemplos:

| Instalación | Ruta del ejecutable de Godot |
|---|---|
| macOS (Steam) | `~/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot` |
| macOS (descarga oficial) | `/Applications/Godot.app/Contents/MacOS/Godot` |
| Windows (Steam) | `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe` |
| Windows (descarga oficial) | `C:\ruta\donde\lo\descomprimiste\Godot_v4.7-stable_win64.exe` |

> En macOS, los accesos directos de Steam en `~/Applications/` son scripts (`run.sh`), no el ejecutable real. Usa la ruta de la carpeta de Steam.

---

## 2. Blender MCP

### 2.1 Instalar el addon en Blender

```bash
uvx mcp-for-blender install-addon
```

El comando copia el addon a la carpeta de addons de tu versión de Blender (en macOS: `~/Library/Application Support/Blender/5.3/scripts/addons/blender_mcp.py`). Si no detecta tu Blender, usa `uvx mcp-for-blender addon-paths` para ver las rutas, o la instalación manual:

1. Descarga [`addon.py`](https://github.com/ahujasid/mcp-for-blender/blob/main/addon.py).
2. En Blender: **Edit → Preferences → Add-ons → Install…** y selecciona `addon.py`.

### 2.2 Activar el addon

1. En Blender: **Edit → Preferences → Add-ons**, busca **"MCP for Blender"** y actívalo.
2. En la vista 3D presiona `N`, abre la pestaña **MCP for Blender** y da clic en **Start MCP Server** si no está corriendo.

> **Blender tiene que estar abierto, con el servidor encendido,** para que el agente pueda usarlo.

### 2.3 Conectarlo al agente de IA

Opción automática, que detecta los clientes instalados (Claude Code, Claude Desktop, Cursor, Codex, VS Code, etc.):

```bash
uvx mcp-for-blender setup
```

O de forma manual, según el cliente (ver la sección 4).

---

## 3. Godot MCP

No necesita addon dentro de Godot. El servidor lanza Godot por su cuenta.

Configura la variable `GODOT_PATH` con la ruta del ejecutable (ver la sección 1) y regístralo en tu agente (sección 4).

Funciones principales: lanzar el editor, ejecutar el proyecto y leer la salida y los errores de depuración, crear escenas, agregar nodos, cargar sprites, exportar mesh libraries y manejar UIDs.

Ruta del proyecto Godot para las herramientas: `godot_zoo-zombie/zoo-zombie-godot`.

---

## 4. Configuración por agente de IA

### Claude Code (CLI)

Desde la raíz del repositorio (`zoozombie/`):

```bash
# Blender
claude mcp add blender -- uvx mcp-for-blender

# Godot (macOS + Steam; ajusta la ruta a tu instalación)
claude mcp add godot \
  -e GODOT_PATH="$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" \
  -- npx @coding-solo/godot-mcp
```

- Por defecto se guarda con alcance **local**: solo tú y solo este proyecto. Agrega `-s user` para usarlo en todos tus proyectos.
- Reinicia Claude Code y verifica con `/mcp` que ambos aparezcan como **connected**.

### Claude Desktop

Edita `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) o `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": ["mcp-for-blender"]
    },
    "godot": {
      "command": "npx",
      "args": ["@coding-solo/godot-mcp"],
      "env": {
        "GODOT_PATH": "/ruta/al/ejecutable/de/Godot"
      }
    }
  }
}
```

Cierra Claude Desktop por completo y vuelve a abrirlo.

### Codex CLI

```bash
codex mcp add blender -- uvx mcp-for-blender
codex mcp add godot --env GODOT_PATH="/ruta/al/ejecutable/de/Godot" -- npx @coding-solo/godot-mcp
```

### Cursor / VS Code / otros clientes

Crea `.cursor/mcp.json` (Cursor) o `.vscode/mcp.json` (VS Code) con el mismo bloque `mcpServers` de Claude Desktop. Estos archivos **no se suben** al repositorio porque contienen rutas de tu máquina.

---

## 5. Verificación rápida

Con Blender abierto y el servidor encendido, pídele al agente:

- *"Dame la información de la escena de Blender"*: debe listar los objetos.
- *"Dime la versión de Godot e información del proyecto en godot_zoo-zombie/zoo-zombie-godot"*: debe responder `4.7.x`.

## 6. Problemas comunes

| Problema | Solución |
|---|---|
| `blender` aparece como *failed* en `/mcp` | Verifica que `uvx` esté en el PATH (`which uvx`) y reinicia el agente |
| El agente no puede conectar con Blender | Abre Blender y da clic en **Start MCP Server** (pestaña N → MCP for Blender). Puerto por defecto: 9876 |
| El addon no aparece en Preferences | Reinicia Blender o instálalo manualmente con `addon.py` |
| `godot` no encuentra el ejecutable | Revisa `GODOT_PATH`: debe apuntar al binario, no al `.app` ni a `run.sh` |
| Cambiaste de versión de Blender | Vuelve a ejecutar `uvx mcp-for-blender install-addon` |

## 7. Ejecutar Blender sin interfaz (para scripts)

Además del MCP, los scripts procedurales se pueden ejecutar sin abrir la interfaz:

```bash
"<ruta a Blender>" -b --python blender_zoo-zombie/scripts/models/food_crate.py -- --output <ruta.glb>
```

En macOS con Steam, el ejecutable de Blender está en:
`~/Library/Application Support/Steam/steamapps/common/Blender/Blender.app/Contents/MacOS/Blender`
