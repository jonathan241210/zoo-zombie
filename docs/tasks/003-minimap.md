# Tareas 003: Minimapa

**Spec:** [`specs/003-minimap.md`](../specs/003-minimap.md) · **Plan:** [`plans/003-minimap.md`](../plans/003-minimap.md)

Convenciones: `[ ]` pendiente · `[x]` hecha · `[P]` paralelizable. Ninguna fase empieza sin aprobación del usuario y cada fase se revisa antes de continuar.

---

## Fase A: Vista base

- [x] T-M01 Crear `MinimapConfig` y `minimap_config.tres` con zoom, tamaño, frecuencia, orientación, máscara y capas — RF-01, RF-03, RF-05, RF-40
- [x] T-M02 Separar la capa visual del GLB estático y mantener actores dinámicos fuera del cull mask del minimapa — RF-02
- [x] T-M03 Crear `minimap.tscn` y `minimap.gd` con `SubViewport`, cámara ortográfica y recorte circular configurable — RF-01, RF-02, RF-09
- [x] T-M04 Dibujar el jugador en el centro, dirección/cono de visión y norte en modo rotatorio — RF-04, RF-06
- [x] T-M05 Implementar norte fijo/rotación del mapa y zoom cercano/lejos — RF-03, RF-05
- [x] T-M06 Integrar el widget en el `CanvasLayer` del HUD sin taparlo y escalarlo según resolución — RF-08
- [ ] T-M07 Revisión manual en movimiento, giros, zoom y resoluciones 1280×720/1920×1080/3840×2160; medir coste del viewport — CA-01, CA-02, CA-06 parcial

## Fase B: Marcadores del nivel

### Subfase B1: puntos de animales (aprobada por solicitud del usuario)

- [x] T-M08a Publicar el registro de animales mediante `EventBus` y recibirlo en el overlay — RF-10
- [x] T-M09a Dibujar puntos distintos para jirafa y elefante en su posición relativa, aplicando zoom y color gris al morir — RF-10
- [ ] T-M09b Revisión manual de posiciones al girar, cambiar zoom y mover los animales — CA-03 parcial

### Trabajo posterior de Fase B (pendiente de aprobación)

- [ ] T-M08 Exponer a `Minimap` referencias públicas a cajas activas, recintos y animales desde sus directores/registro — plan §2.2
- [ ] T-M09 Añadir iconos distintos y coordenadas de recintos, refugios libres y punto de cafetería — RF-11, RF-12, RF-16
- [ ] T-M10 Registrar aparición, recogida y descarte de cajas de comida; actualizar iconos sin buscar por rutas frágiles — RF-13
- [ ] T-M11 Implementar conversión mundo→minimapa para mapa giratorio/fijo y recorte de objetivos al borde — RF-03, RF-07
- [ ] T-M12 Añadir textos/leyenda y claves de traducción español/inglés para etiquetas — RF-17, RF-31, RF-43
- [ ] T-M13 Revisión manual de posiciones/estados de animales, recintos, refugios y cajas — CA-03

## Fase C: Mapa completo

- [ ] T-M14 Agregar `map_toggle` (M / Select) y `minimap_zoom` (Z / R3) al `InputMap` y la pantalla de Controles — RF-42
- [ ] T-M15 Crear mapa completo con misma textura, iconos, etiquetas y leyenda — RF-30, RF-31
- [ ] T-M16 Pausar/reanudar sin reiniciar sistemas de escena, con opción técnica configurable — RF-32
- [ ] T-M17 Añadir zoom, paneo y selección/fijación de punto de ruta con mouse, teclado y gamepad — RF-23, RF-33
- [ ] T-M18 Prueba manual de apertura/cierre, movimiento de mapa, pausa y punto de ruta — CA-07, CA-10

## Fase D: Objetivos guiados

- [ ] T-M19 Implementar `MapObjectiveSelector` con prioridades RF-21/22 a partir de señales de hambre, refugio, rescate y recinto atacado — RF-20 a RF-22
- [ ] T-M20 Mantener el objetivo destacado con pulso y flecha de borde; ocultar los marcadores informativos fuera de rango — RF-07, RF-20
- [ ] T-M21 Agregar preferencia para desactivar la guía al existir `SettingsManager` — RF-25, RF-40
- [ ] T-M22 Dibujar guía de ruta siguiendo navegación disponible; mantener flecha como alternativa si no hay ruta — RF-24
- [ ] T-M23 Revisar manualmente cambios de prioridad — CA-05

## Fase E: Datos avanzados y accesibilidad

- [ ] T-M24 Mostrar munición solo dentro del alcance de luz cuando exista `AmmoSpawnDirector` — RF-14, CA-04
- [ ] T-M25 Mostrar zombis cercanos y diferenciar destructores al existir `ZombieSpawner`/roles — RF-15
- [ ] T-M26 Señalar estado débil/escapado/muerto, recintos atacados/destruidos y refugios disponibles — RF-10 a RF-12
- [ ] T-M27 Agregar opciones de forma, tamaño, orientación, visibilidad y guía; guardar preferencias con `SettingsManager` — RF-40
- [ ] T-M28 Revisar formas de iconos, traducciones, gamepad, resoluciones y criterios CA-01 a CA-10 — RF-41, RF-43, CA-01 a CA-10
- [ ] T-M29 Medir 60 FPS a 1080p con el máximo de zombis una vez implementadas las oleadas — CA-06
