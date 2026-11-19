# Spec 003: Minimapa del HUD

**Estado:** Fases A y B1 aprobadas por solicitud del usuario · **Versión:** 0.3 · **Fecha:** 2026-11-18
**Plan:** [`plans/003-minimap.md`](../plans/003-minimap.md) · **Tareas:** [`tasks/003-minimap.md`](../tasks/003-minimap.md)
**Depende de:** [`specs/001-zoo-survival.md`](001-zoo-survival.md) y [`specs/002-menus-and-onboarding.md`](002-menus-and-onboarding.md)

---

## 1. Resumen

Un **minimapa** en la esquina **superior derecha** del HUD, al estilo de GTA 5, que le muestra al jugador **dónde está y hacia dónde debe ir**. Es una vista del zoológico desde arriba que sigue al jugador y marca los puntos importantes: animales, recintos, refugios, cajas de comida, munición y amenazas.

Además del minimapa, hay un **mapa completo** que se abre a pantalla completa para ver todo el zoológico de una vez.

Esta spec **amplía** los requisitos RF-46 y RF-104 de la spec 001 (marcadores hacia animales escapados y refugios libres). El minimapa es la forma principal de cumplirlos.

## 2. Historias de usuario

- **HU-01:** Como jugador, quiero ver un mapa pequeño en una esquina para saber dónde estoy sin perder de vista la acción.
- **HU-02:** Como jugador, quiero ver hacia dónde mira mi personaje en el mapa para orientarme.
- **HU-03:** Como jugador, quiero ver dónde están mis animales y sus recintos para decidir a cuál atender primero.
- **HU-04:** Como jugador, quiero ver dónde hay cajas de comida para llevarlas rápido a los animales.
- **HU-05:** Como jugador, quiero ver hacia dónde debo ir (el objetivo más urgente) sin tener que adivinar.
- **HU-06:** Como jugador, quiero ver los zombis cercanos y los recintos bajo ataque para reaccionar a tiempo.
- **HU-07:** Como jugador, quiero abrir un mapa grande para planear mi ruta.

## 3. Requisitos funcionales

### 3.1 Minimapa en el HUD

| ID | Requisito |
|---|---|
| RF-01 | El minimapa se muestra en la **esquina superior derecha** del HUD durante la partida. Forma configurable: **circular** (por defecto) o cuadrada. |
| RF-02 | Es una **vista cenital** (desde arriba) del zoológico real, centrada en el jugador. Su fondo se obtiene del mapa existente, sin dibujarlo a mano. |
| RF-03 | **Rotación configurable:** (a) el mapa **gira** y el jugador siempre mira hacia arriba (estilo GTA, valor por defecto) o (b) el mapa **queda fijo** con el norte arriba y el icono del jugador gira. |
| RF-04 | El icono del jugador siempre está en el centro (modo giratorio) y muestra su **dirección de mirada** con un cono de visión. |
| RF-05 | Tiene **zoom configurable**: radio visible en metros. Hay al menos dos niveles (cercano y lejano) que se cambian con una tecla o botón. |
| RF-06 | Muestra un indicador de **norte** (N) en el borde cuando el mapa gira. |
| RF-07 | Los iconos que quedan **fuera del radio visible** se pegan al borde del minimapa apuntando hacia su posición real, **solo si son marcadores de objetivo** (RF-20 a RF-23). Los demás desaparecen al salir. |
| RF-08 | El minimapa no tapa elementos del HUD existentes (RF-100 a RF-10A de la spec 001) y se adapta a resoluciones de 1280×720 a 3840×2160 (RF-103 de la spec 002). |
| RF-09 | Se actualiza al menos 20 veces por segundo y **no baja el rendimiento** más de lo permitido en CA-06. |

### 3.2 Qué muestra (iconos)

| ID | Elemento | Icono y comportamiento |
|---|---|---|
| RF-10 | **Jirafa** y **elefante** | Un punto distinto por animal, en su posición actual y siempre visible dentro del radio del minimapa. El color distingue jirafa y elefante; si muere, el punto pasa a gris. Los estados débil y escapado se añadirán cuando esos estados existan en el sistema de animales. |
| RF-11 | **Recintos ocupados** | Contorno del recinto. Parpadea en rojo si está **bajo ataque** (RF-103 de la spec 001). Se oscurece si está destruido. |
| RF-12 | **Refugios libres** | Icono de refugio en cada refugio libre e intacto. Solo se resaltan mientras haya un animal escapado. |
| RF-13 | **Cajas de alimento** | Icono de caja en cada caja activa. |
| RF-14 | **Cajas de munición** | Icono de munición **solo cuando el jugador está dentro del alcance de la luz de la caja** (RF-59 de la spec 001). No se revelan desde lejos, para conservar la exploración. |
| RF-15 | **Zombis** | Punto rojo pequeño en cada zombi **dentro de un radio de detección** configurable. Los destructores se distinguen del resto. |
| RF-16 | **Cafetería** (punto de aparición) | Icono fijo de cafetería. |
| RF-17 | **Zonas importantes del mapa** | Etiquetas de texto en el mapa grande: recintos, cafetería y refugios. Los nombres son claves de traducción. |

### 3.3 Objetivo guiado (hacia dónde ir)

| ID | Requisito |
|---|---|
| RF-20 | Hay un **marcador de objetivo** destacado (icono grande con pulso) que apunta al destino más urgente según la situación. |
| RF-21 | Prioridad del objetivo, de mayor a menor: (1) **recinto bajo ataque**, (2) **animal escapado** (o el refugio libre si el jugador ya lo atrae), (3) **animal con hambre** (barra de alimento en 0), (4) **caja de alimento más cercana** si hay animal con hambre y el jugador no carga ninguna. |
| RF-22 | Si el jugador **carga una caja**, el objetivo es el **comedero del animal que más lo necesita**. |
| RF-23 | El jugador puede **fijar un marcador propio** en el mapa completo (punto de ruta). Aparece en el minimapa y se quita al llegar o al fijarlo de nuevo. |
| RF-24 | El objetivo se puede mostrar con una **línea guía sobre el camino** (siguiendo el navmesh) además de la flecha de borde. Configurable: activada por defecto. |
| RF-25 | Se puede **desactivar** el objetivo guiado en Configuración, para quien prefiera explorar sin ayuda. |

### 3.4 Mapa completo

| ID | Requisito |
|---|---|
| RF-30 | Con una tecla o botón (**M** / **Select**), se abre el **mapa completo**: vista cenital de todo el zoológico, centrada en el jugador, con **zoom y desplazamiento**. |
| RF-31 | Muestra los mismos iconos que el minimapa, con etiquetas. Además muestra la **leyenda** de los iconos. |
| RF-32 | Mientras está abierto, el juego **se pausa** (con opción configurable para no pausar). Los temporizadores de hambre y oleada siguen la regla de RF-80 de la spec 002. |
| RF-33 | Desde este mapa se puede fijar el marcador propio (RF-23). Se maneja con mouse, teclado o gamepad (RF-100 de la spec 002). |

### 3.5 Configuración y accesibilidad

| ID | Requisito |
|---|---|
| RF-40 | En **Configuración > Gameplay y accesibilidad** (RF-73 de la spec 002) se puede: mostrar u ocultar el minimapa, cambiar forma, rotación, tamaño (pequeño / mediano / grande), zoom inicial, y activar o no el objetivo guiado y la línea guía. |
| RF-41 | Los iconos no dependen solo del color: cada tipo tiene una **forma distinta**, para jugadores con daltonismo. |
| RF-42 | Las nuevas acciones (**mapa completo**, **cambiar zoom del minimapa**) aparecen en la pantalla informativa de **Controles** con sus teclas y botones predeterminados. No se reasignan (spec 002 RF-62). |
| RF-43 | Todos los textos del minimapa y del mapa completo están en el archivo de traducción (español e inglés). |

## 4. Valores configurables

Se guardan en un recurso `.tres` (por ejemplo `MinimapConfig`), nunca escritos en el código.

| Parámetro | Valor inicial |
|---|---|
| Forma | Circular |
| Rotación | Gira con el jugador |
| Tamaño en pantalla | 220 px (a 1080p) |
| Radio visible, zoom cercano / lejano | 40 m / 90 m |
| Ángulo del cono de visión | 60° |
| Radio visual de los puntos de animales | 6 px |
| Radio de detección de zombis en el minimapa | 30 m |
| Frecuencia de actualización | 20 Hz |
| Tecla mapa completo / zoom | M / Z |
| Gamepad mapa completo / zoom | Select / R3 |
| Objetivo guiado y línea guía | Activados |
| El mapa completo pausa el juego | Sí |

## 5. Criterios de aceptación

- **CA-01:** El minimapa aparece arriba a la derecha desde que empieza la partida y no tapa el HUD existente a 1280×720 ni a 4K.
- **CA-02:** Al caminar y girar, el icono del jugador y el cono de visión coinciden con lo que se ve en pantalla, en ambos modos de rotación.
- **CA-03:** La jirafa, el elefante, los recintos, los refugios libres y las cajas de alimento aparecen en su posición real. Los estados (débil, escapado, muerto, bajo ataque) cambian el icono.
- **CA-04:** Las cajas de munición solo aparecen en el minimapa dentro del alcance de su luz.
- **CA-05:** El marcador de objetivo cambia de destino al cumplirse cada prioridad de RF-21 y RF-22, y su flecha apunta al borde cuando el destino está fuera de vista.
- **CA-06:** Con el máximo de zombis vivos, el juego mantiene **60 FPS a 1080p** en la máquina de desarrollo con el minimapa activo (CA-15 de la spec 001).
- **CA-07:** El mapa completo se abre y cierra con teclado y con gamepad, permite hacer zoom, desplazarse y fijar un marcador propio.
- **CA-08:** Todas las opciones de RF-40 se aplican al momento y se conservan al reiniciar el juego.
- **CA-09:** Los valores de la sección 4 se cambian en un `.tres` sin tocar el código.
- **CA-10:** El minimapa funciona con gamepad, sin mouse, para todas sus acciones.

## 6. Fuera de alcance

- Revelar el mapa por zonas explorado (niebla de guerra).
- Mostrar pisos o interiores a distintos niveles.
- Marcadores colocados por otros jugadores (no hay multijugador).
- Minimapa en la pantalla de título o en los menús.
- Cambiar o ampliar el modelo del mapa en Blender: se usa el mapa actual (`assets/models/map/zoo_map.glb`).

## 7. Supuestos y preguntas abiertas

| ID | Tema | Supuesto por defecto | Estado |
|---|---|---|---|
| D-01 | Tipo de minimapa | Esquina superior derecha, estilo GTA 5, con objetivo guiado | ✅ Confirmado (2026-11-18) |
| D-02 | Origen del mapa | Se reutiliza el mapa actual; no se hace un mapa nuevo en Blender | ✅ Confirmado (2026-11-18) |
| S-01 | Rotación del minimapa | El mapa gira con el jugador (como GTA 5), con opción de norte fijo | Supuesto |
| S-02 | Zombis visibles en el minimapa | Solo los cercanos (30 m), no todos | Supuesto |
| S-03 | Munición en el minimapa | Solo se ve al estar cerca; no se revela desde lejos | Supuesto |
| S-04 | Mapa completo | Se incluye (tecla M) y pausa el juego | Supuesto |
| S-05 | Fuente visual del fondo | Una cámara cenital renderizada a una textura (`SubViewport`) o una imagen cenital pre-generada del mapa. La decisión técnica va en el plan | Pendiente de plan |
| S-06 | Línea guía sobre el camino | Activada por defecto, siguiendo el navmesh | Supuesto |
