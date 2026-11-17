# Zoo Zombie

Videojuego 3D de un zoológico infestado de zombies, desarrollado con **Blender** (modelado) y **Godot** (lógica del juego).

## Estructura

| Carpeta | Contenido |
|---|---|
| `blender_zoo-zombie/` | Archivos `.blend` (mapa del zoológico y modelos propios) |
| `godot_zoo-zombie/` | Proyecto de Godot |
| `assets/modelos/` | Modelos 3D descargados (`.glb`, `.fbx`, `.obj`) |
| `assets/texturas/` | Texturas e imágenes |
| `assets/audio/` | Música y efectos de sonido |
| `docs/specs/` | Especificaciones del juego (metodología SDD) |

## Cómo colaborar

```bash
git clone https://github.com/jonathan241210/zoo-zombie.git
cd zoo-zombie
git pull                      # antes de empezar a trabajar
git add .
git commit -m "Descripción del cambio"
git push
```

> Los archivos `.blend` son binarios y Git no puede fusionarlos: coordinen quién edita cada archivo para evitar conflictos.
