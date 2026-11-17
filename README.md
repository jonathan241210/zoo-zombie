# Zoo Zombie

Videojuego 3D de un zoológico infestado de zombies, desarrollado con **Blender** (modelado) y **Godot** (lógica del juego).

## Estructura

| Carpeta | Contenido |
|---|---|
| `blender_zoo-zombie/` | Archivos `.blend` (mapa del zoológico y modelos propios) |
| `godot_zoo-zombie/zoo-zombie-godot/` | Proyecto de Godot 4.7 |
| `assets/models/` | Modelos 3D descargados (`.glb`, `.fbx`, `.obj`) |
| `assets/textures/` | Texturas e imágenes |
| `assets/audio/` | Música y efectos de sonido |
| `docs/` | Documentación: constitución, specs SDD, decisiones (ADR) y guías |

## Documentación

- [`AGENTS.md`](AGENTS.md): reglas de trabajo (idioma, commits, flujo SDD). **Léelo primero.**
- [`docs/constitution.md`](docs/constitution.md): principios del proyecto.
- [`docs/specs/`](docs/specs/), [`docs/plans/`](docs/plans/), [`docs/tasks/`](docs/tasks/): spec, plan y tareas (SDD). Juego base: `001-zoo-survival.md`; menús e instrucciones: `002-menus-and-onboarding.md`.
- [`docs/assets.md`](docs/assets.md): modelos y audio necesarios.
- [`docs/setup/mcp.md`](docs/setup/mcp.md): configurar MCP de Blender y Godot.

## Cómo colaborar

```bash
git clone https://github.com/jonathan241210/zoo-zombie.git
cd zoo-zombie
git pull                      # antes de empezar a trabajar
git add .
git commit -m "feat(ámbito): descripción del cambio"
git push
```

> Los archivos `.blend` son binarios y Git no puede fusionarlos: coordinen quién edita cada archivo para evitar conflictos.
