# Spec 005: Salto y sprint

**Estado:** Borrador, pendiente de aprobación · **Versión:** 0.1 · **Fecha:** 2026-11-18
**Plan:** `plans/005-jump-and-sprint.md` (aún no existe) · **Tareas:** `tasks/005-jump-and-sprint.md` (aún no existe)
**Depende de:** [`specs/001-zoo-survival.md`](001-zoo-survival.md) y [`specs/002-menus-and-onboarding.md`](002-menus-and-onboarding.md)

---

## 1. Resumen

El jugador puede **saltar** y **correr (sprint) manteniendo Shift**. Esta spec **reemplaza** la decisión D-12 de la spec 001 ("el jugador no puede saltar") y precisa el RF-01.

## 2. Historias de usuario

- **HU-01:** Como jugador, quiero saltar para sortear obstáculos bajos y moverme con más libertad.
- **HU-02:** Como jugador, quiero correr manteniendo Shift para escapar de los zombis o llegar rápido a un animal.

## 3. Requisitos funcionales

### 3.1 Salto

| ID | Requisito |
|---|---|
| RF-01 | El jugador salta con **Espacio** (teclado) o **B / Círculo** (gamepad). La acción de input nueva se llama `jump`. |
| RF-02 | La altura del salto es configurable (inicial **~1 m**). La gravedad y la velocidad de caída son configurables. |
| RF-03 | **No se puede saltar mientras se carga una caja** (estado CARGANDO, RF-05 de la spec 001), igual que no se pueden usar armas. |
| RF-04 | Se puede saltar con cualquier arma equipada. **No hay daño por caída**. |
| RF-05 | Solo se salta **desde el suelo** (sin doble salto). Opcional: un breve margen (*coyote time*) configurable al salir de un borde. |
| RF-06 | El jugador conserva su impulso horizontal en el aire y puede corregirlo con un control reducido (configurable). |
| RF-07 | El salto tiene sonido de despegue y de aterrizaje. Al aterrizar, la vista tiene un leve movimiento (intensidad configurable, relacionada con la reducción de movimiento de cámara de RF-73 de la spec 002). |
| RF-08 | El salto **no permite** saltar los **recintos** ni sus cercas, ni salir del mapa. Las cercas y los límites del mapa son más altos que la altura máxima del salto o tienen colisión de bloqueo. |
| RF-09 | Los zombis y los animales **no se ven afectados** por el salto (no esquivan ataques al saltar, por ahora): el salto es solo movimiento. |

### 3.2 Sprint con Shift

| ID | Requisito |
|---|---|
| RF-10 | El sprint ya existe en la acción `sprint` (Shift izquierdo y L3). Se **mantiene mientras se pulsa**: al soltar Shift el jugador vuelve a caminar. |
| RF-11 | Correr es **ilimitado**, sin barra de resistencia. Velocidad inicial **7.0 m/s** (RF de la spec 001, sección 6), configurable. |
| RF-12 | Solo se corre **hacia adelante o en diagonal hacia adelante**, sin correr hacia atrás (configurable). |
| RF-13 | **No se puede correr mientras se carga una caja** (CARGANDO): solo caminar lento (3.2 m/s). Si el jugador estaba corriendo, al tomar la caja baja a esa velocidad. |
| RF-14 | Se puede correr con cualquier arma. El balanceo de cámara al correr es opcional y configurable (relacionado con RF-73 de la spec 002). |
| RF-15 | El sprint se puede **mantener en el aire**: si el jugador salta corriendo, conserva su velocidad. |

### 3.3 Controles

| ID | Requisito |
|---|---|
| RF-20 | La acción `jump` se agrega a la pantalla de **Controles** y se puede reasignar (RF-61 de la spec 002). |
| RF-21 | Valores por defecto: **Saltar** = Espacio / B (Xbox) / Círculo (PlayStation). **Correr** = Shift izquierdo / L3 (mantener). |
| RF-22 | **Cómo jugar** y los consejos indican cómo saltar y correr. Nuevo consejo **TIP-15**, primera vez que el jugador se mueve: "Corre con [Shift], salta con [Espacio]." |

## 4. Valores configurables

Se guardan en el recurso de configuración del jugador (`.tres`), no en el código.

| Parámetro | Valor inicial |
|---|---|
| Altura del salto | 1.0 m |
| Gravedad | 20 m/s² |
| Control en el aire (0–1) | 0.6 |
| Margen de salto tras salir de un borde (*coyote time*) | 0.1 s |
| Velocidad caminando / corriendo / cargando | 4.5 / 7.0 / 3.2 m/s |
| Correr hacia atrás | No |

## 5. Criterios de aceptación

- **CA-01:** Con **Espacio** (o B / Círculo) el jugador salta ~1 m. Con una caja en las manos, la acción no hace nada.
- **CA-02:** Manteniendo **Shift** el jugador corre a 7.0 m/s. Al soltarlo, camina a 4.5 m/s. Con una caja, no corre.
- **CA-03:** No hay daño al caer, no hay doble salto y no se puede saltar sobre las cercas ni salir del mapa.
- **CA-04:** Saltar y correr funcionan con teclado y mouse y con gamepad, y la acción `jump` se reasigna en Controles.
- **CA-05:** El jugador no se atora en el navmesh ni en las colisiones del mapa al saltar y aterrizar, y el rendimiento sigue en 60 FPS (CA-15 de la spec 001).
- **CA-06:** Los valores de la sección 4 se cambian en el `.tres` sin tocar el código.

## 6. Fuera de alcance

- Resistencia (stamina) del jugador al correr.
- Doble salto, agacharse, deslizarse o escalar.
- Daño por caída.
- Esquivar zombis saltando.

## 7. Supuestos y preguntas abiertas

| ID | Tema | Decisión | Estado |
|---|---|---|---|
| D-01 | Salto | El jugador puede saltar, revirtiendo D-12 de la spec 001 | ✅ Confirmado (2026-11-18) |
| D-02 | Saltar cargando una caja | No se puede | ✅ Confirmado (2026-11-18) |
| D-03 | Altura y daño por caída | ~1 m, sin daño | ✅ Confirmado (2026-11-18) |
| D-04 | Sprint | Ilimitado, mantener Shift | ✅ Confirmado (2026-11-18) |
| D-05 | Correr cargando una caja | No se puede (3.2 m/s) | ✅ Confirmado (2026-11-18) |
| S-01 | **Botón de salto en gamepad** | Elegiste A / Cruz, pero **A / Cruz ya es "Interactuar"** (spec 001 y `interact` en el input map). Propongo **B / Círculo** para no chocar. Alternativa: A para ambos, con prioridad a interactuar | **Pendiente de tu respuesta** |
| S-02 | Correr hacia atrás | No | Supuesto |
| S-03 | Control en el aire | 60 % | Supuesto |
| S-04 | Cercas de recintos | No se pueden saltar | Supuesto |
