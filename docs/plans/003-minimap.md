# Plan técnico 003: Minimapa

**Estado:** Fases A y B1 aprobadas por solicitud del usuario · **Versión:** 0.2 · **Fecha:** 2026-11-18
**Spec:** [`specs/003-minimap.md`](../specs/003-minimap.md) · **Tareas:** [`tasks/003-minimap.md`](../tasks/003-minimap.md)
**Se apoya en:** [`plans/001-zoo-survival.md`](001-zoo-survival.md) (nivel, animales, cajas, recintos y HUD) y [`plans/002-menus-and-onboarding.md`](002-menus-and-onboarding.md) (`InputGlyphs` y pantalla informativa de controles).

---

## 1. Análisis del nivel actual

- El mapa jugable es `assets/models/map/zoo_map.glb`, instanciado como `ZooLevel/ZooMap`. El nivel ya expone `PlayerSpawn`, seis puntos de aparición de comida, ocho puntos candidatos de zombi y dos anclas de comederos.
- `EnclosureRegistry` crea recintos a partir de nombres de nodos del GLB y `EnclosureConfig`; no existe todavía una lista independiente de refugios dibujada como marcadores del minimapa.
- `FoodCrateDirector` conoce las cajas activas, pero necesita exponerlas para el HUD. Aún no hay `ZombieSpawner`, `AmmoSpawnDirector`, `AnimalNeeds` ni `WaveManager` para suministrar todos los datos que la spec quiere mostrar.
- El HUD actual es un `CanvasLayer` en `game.tscn`, con estado del jugador y avisos contextuales. Ahí se integra el minimapa.
- El mundo usa la capa visual por defecto para mapa y actores. La cámara del minimapa necesita una capa exclusiva para el mapa estático, para que no dibuje al jugador ni a animales encima de su propio icono.

## 2. Arquitectura

### 2.1 Render del mapa

Se reutiliza el mapa 3D real en un `SubViewport` cuadrado de baja resolución (256×256), actualizado a la frecuencia de `MinimapConfig` (20 Hz). Una cámara ortográfica cenital sigue al jugador para el minimapa y mira el centro del zoológico para el mapa completo. No se genera ni modifica un mapa fuente en Blender.

El GLB estático del zoológico se pone en una capa visual dedicada al mapa; los modelos dinámicos quedan fuera de esa capa y se dibujan como iconos 2D. Esto evita el duplicado del jugador y de los animales, y limita el render secundario a una textura pequeña. El `SubViewport` comparte el `World3D` del juego, pero su `cull_mask` solo incluye el mapa. Un shader recorta la textura al círculo configurable.

### 2.2 Escenas y componentes

| Archivo | Responsabilidad |
|---|---|
| `scripts/data/minimap_config.gd`, `config/minimap_config.tres` | Forma, tamaño, zoom, frecuencia, capas y opciones visuales configurables |
| `scenes/ui/minimap.tscn`, `scripts/ui/minimap.gd` | Widget HUD; cámara, render, iconos, brújula, zoom y panel del mapa completo |
| `shaders/minimap_circle.gdshader` | Máscara circular opcional para la textura del `SubViewport` |
| `scripts/ui/minimap_marker.gd` | Datos y actualización de iconos de entidades; proyecta X/Z del mundo al panel |
| `scripts/systems/map_objective_selector.gd` | Elige el objetivo más urgente a partir de estados publicados por los sistemas existentes |

El widget recibe referencias explícitas del `Game` al `ZooLevel`, jugador, `FoodCrateDirector` y `EnclosureRegistry`. No descubre dependencias por rutas de nodos. Para entidades móviles usa grupos/registro y señales de alta/baja; los marcadores fijos leen los `Marker3D` del nivel.

### 2.3 Coordenadas y modos

- `map_radius` define los metros visibles desde el centro en el minimapa. El `Camera3D` ortográfico usa `size = map_radius * 2`.
- Con el mapa giratorio, la cámara y los marcadores giran en sentido contrario al yaw del jugador; el icono de jugador apunta arriba. Con norte fijo, el fondo no gira y el icono rota según el yaw.
- Los marcadores se colocan por transformación relativa al jugador y al yaw activo. Los objetivos fuera del círculo se limitan al borde y reciben una flecha; los marcadores informativos se ocultan fuera del radio.
- Zoom y rotación se leen de `MinimapConfig`; el estado de presentación se conserva durante la partida. Persistir preferencias de usuario espera al `SettingsManager` completo de la spec 002.

### 2.4 Mapa completo e inputs

`map_toggle` (M / Select) abre o cierra el panel ampliado; `minimap_zoom` (Z / R3) alterna los radios cercano y lejano. El mapa completo pausa por defecto según RF-32, y muestra leyenda, etiquetas, objetivo, zoom y desplazamiento. Las acciones se agregan al `InputMap` y a la tabla de controles de solo consulta; no se construye reasignación.

El punto de ruta propio se representa como un marcador local del widget. Para quitarlo, el jugador lo vuelve a fijar o se acerca a él según RF-23. Un clic / confirmación del gamepad fija el destino en el mapa completo.

### 2.5 Dependencias de objetivos y marcadores avanzados

El minimapa base puede mostrar jugador, animales actuales, recintos, refugios configurados y cajas de comida. Los elementos condicionales se conectan cuando sus fuentes existan:

- hambre/objetivo de alimentación: Fase 4 de la 001 (`AnimalNeeds`, T-040 a T-044);
- recintos bajo ataque y zombis: Fases 6–8 de la 001 (`Enclosure`, `Zombie`, `WaveManager`);
- animales escapados/seguimiento y refugios: estados de rescate de la Fase 7;
- munición: `AmmoSpawnDirector` de la Fase 5.

El selector implementa la prioridad RF-21 con señales y consultas a esos sistemas, no con temporizadores duplicados. La línea guía sobre el navmesh solo se activa cuando exista la navegación de zombis y se pueda reutilizar una ruta válida; mientras tanto se usa la flecha de objetivo.

## 3. Valores en `MinimapConfig`

Además de los valores de la spec, se exponen: resolución interna del viewport, radio máximo, altura de cámara, escala respecto a 1080p, actualización en Hz, color de máscara y teclas predeterminadas. Ninguno se codifica como valor de balance dentro del script.

## 4. Fases y resultados

| Fase | Resultado comprobable | Requisitos |
|---|---|---|
| A. Vista base | Minimapa circular con fondo del zoo, jugador, cono, norte, rotación/zoom y anclaje responsive | RF-01 a RF-09, RF-40/41 parcialmente |
| B. Marcadores del nivel | Animales, recintos, refugios y cajas de comida, iconos distintos y borde para objetivos | RF-10 a RF-13, RF-17, RF-20 parcialmente |
| C. Mapa completo | Panel grande, pausa, navegación, zoom/pan, leyenda y marcador personal | RF-23, RF-30 a RF-33 |
| D. Objetivos de supervivencia | Prioridad urgente, indicadores de hambre/escape/ataque y guía de ruta cuando haya datos | RF-20 a RF-25 |
| E. Sistemas y accesibilidad | Munición/zombis, controles, traducciones, ajustes y rendimiento final | RF-14 a RF-16, RF-40 a RF-43 |

La subfase **B1** implementa exclusivamente los puntos de jirafa y elefante. `Animal` anuncia su registro por `EventBus`; el overlay conserva las referencias y dibuja la posición en coordenadas relativas al jugador, con colores distintos y gris para animales muertos. Los puntos se limitan al área visible y siguen los dos niveles de zoom. Los estados débil y escapado quedan pendientes hasta que la lógica de animales los implemente.

Cada fase termina con revisión manual de sus criterios antes de comenzar la siguiente. La Fase A no espera a IA de zombis ni a los sistemas de hambre.

## 5. Riesgos y límites

- El fondo comparte el mapa 3D; capas visuales mal configuradas pueden ocultar edificios o incluir actores dinámicos. La Fase A valida cull mask y orientación antes de añadir iconos.
- Una cámara cenital puede quedar tapada por techos/árboles. Se usará una cámara alta con proyección ortográfica y materiales/capas del mapa; si el resultado no es legible, se cambia a una captura cenital estática derivada del GLB antes de extender la arquitectura.
- CA-06 depende del máximo de zombis y de una máquina de referencia; hasta que existan `Zombie` y `WaveManager`, solo se mide el coste propio del viewport.
- La línea de navegación y la prioridad de objetivos se posponen para no inventar estados que los sistemas del juego aún no emiten.
