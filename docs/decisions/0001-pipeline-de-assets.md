# ADR-0001: Pipeline de assets 3D

**Estado:** Propuesto · **Fecha:** 2026-11-16

## Contexto

El juego combina modelos descargados (Sketchfab, Mixamo, etc.), modelos generados con scripts de Blender y un mapa hecho en Blender. Godot solo puede cargar archivos que estén dentro de su carpeta de proyecto (`res://`). El equipo colabora por GitHub, y los archivos binarios (`.blend`, `.glb`) no se pueden fusionar.

## Decisión

1. **Formato de intercambio: GLB** (glTF 2.0 binario). Godot lo importa de forma nativa y guarda malla, materiales, texturas y animaciones en un solo archivo.
2. **Tres ubicaciones con roles distintos:**
   - `assets/` (raíz): las **descargas originales**, sin modificar. Sirve como fuente y para verificar licencias.
   - `blender_zoo-zombie/`: los `.blend` de trabajo y los **scripts Python** procedurales (`scripts/`).
   - `godot_zoo-zombie/zoo-zombie-godot/assets/models/`: los **GLB listos para el juego**, que son los únicos que usa Godot.
3. **Convenciones de exportación:** `+Y up`, modificadores aplicados, escala real en metros y animaciones como acciones con nombre en inglés (`idle`, `walk`, `eat`, `weak`, `death`, `attack`, `hit`, `fire`, `reload`, `carry`).
4. **Colisiones del mapa** con los sufijos de importación de Godot (`-col`, `-colonly`, `-convcolonly`) sobre mallas simplificadas.
5. Si algún archivo supera los ~50 MB, se adopta **Git LFS** para `*.glb`, `*.blend` y `*.fbx`.

## Consecuencias

- ✅ Se sabe siempre cuál es la fuente y cuál el resultado. Un asset modificado se puede regenerar.
- ✅ Los modelos procedurales son reproducibles: basta con volver a ejecutar su script.
- ⚠️ Un modelo ocupa espacio dos veces: la descarga original y el GLB del juego. Es aceptable mientras los archivos sean pequeños.
- ⚠️ Los `.blend` deben editarse por una persona a la vez, coordinándose para evitar conflictos.

## Alternativas descartadas

- **Importar `.blend` directamente en Godot:** requiere tener Blender configurado en cada máquina y la importación es más lenta y frágil entre versiones.
- **FBX:** da problemas de escala, materiales y animaciones en Godot 4.
