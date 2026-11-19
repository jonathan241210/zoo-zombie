# Plan técnico 005: Salto y sprint

**Estado:** Borrador, pendiente de aprobación · **Versión:** 0.1 · **Fecha:** 2026-11-18
**Spec:** [`specs/005-jump-and-sprint.md`](../specs/005-jump-and-sprint.md) · **Tareas:** `tasks/005-jump-and-sprint.md` (aún no existe)
**Se apoya en:** [`plans/001-zoo-survival.md`](001-zoo-survival.md) (jugador en primera persona, `PlayerCarry`) y [`plans/002-menus-and-onboarding.md`](002-menus-and-onboarding.md) (`InputGlyphs`, pantalla de controles).

---

## 1. Estado actual del código

Revisado en `godot_zoo-zombie/zoo-zombie-godot/`:

| Elemento | Estado |
|---|---|
| [`player_controller.gd`](../../godot_zoo-zombie/zoo-zombie-godot/scripts/player/player_controller.gd) | `CharacterBody3D` con gravedad (`ProjectSettings default_gravity`), caminar, **sprint ya implementado** (`get_target_speed`: carga > sprint hacia adelante > caminar). **No hay salto.** |
| `player_config.gd` / `player_config.tres` | Tiene `walk_speed`, `sprint_speed`, `carry_speed`, aceleración y deceleración. Faltan los valores de salto |
| `project.godot` (input map) | Existe `sprint` (Shift izquierdo + L3). **No existe `jump`** |
| `PlayerCarry` | Ya expone `is_carrying()` y `can_use_weapons()` |
| Cercas de recintos | Colisión en la capa 1 (`world`) generada por `zoo_map_post_import.gd` |

Por tanto el **sprint (RF-10 a RF-15) casi está hecho**: solo hace falta el control en el aire y la prueba. El trabajo real es el salto.

## 2. Arquitectura

No se crean escenas ni autoloads nuevos. Los cambios son pequeños y se concentran en el controlador, la configuración y el input map.

### 2.1 Cambios por archivo

| Archivo | Cambio |
|---|---|
| `scripts/data/player_config.gd` | Nuevas variables exportadas: `jump_height` (1.0 m), `gravity` (20.0 m/s²), `air_control` (0.6), `coyote_time` (0.1 s), `jump_buffer_time` (0.1 s), `allow_backward_sprint` (false) |
| `config/player_config.tres` | Valores iniciales de la spec 005 §4 |
| `project.godot` | Nueva acción `jump`: **Espacio** + **B / Círculo** (botón 1 del joypad). Ver §3 |
| `scripts/player/player_controller.gd` | Salto, coyote time, jump buffer, control en el aire, sprint mantenido en el aire y bloqueo al cargar |
| `scripts/autoload/input_glyphs.gd` | Registrar la acción `jump` para que muestre su icono |
| `localization/` (CSV) | Claves `ACTION_JUMP`, `TIP_MOVE_SPRINT_JUMP` y texto de controles |
| `tests/test_player_movement.gd` | Pruebas unitarias del cálculo del salto y de la velocidad |

### 2.2 Salto

Se calcula la velocidad inicial para alcanzar `jump_height` con la gravedad configurada:

```
jump_velocity = sqrt(2 * gravity * jump_height)    # 1.0 m, 20 m/s² → 6.32 m/s
```

En `_physics_process`:

1. La gravedad usa `config.gravity` en vez del valor global de Godot (la spec pide 20 m/s², más ágil que 9.8 en primera persona).
2. Se guarda `_coyote_timer`: se reinicia a `coyote_time` mientras `is_on_floor()`, y baja en el aire.
3. Se guarda `_jump_buffer_timer`: se reinicia a `jump_buffer_time` al pulsar `jump`. Así un salto pulsado justo antes de aterrizar se ejecuta.
4. Si `_jump_buffer_timer > 0` y `_coyote_timer > 0` y `can_jump()`, entonces `velocity.y = jump_velocity` y se anulan ambos temporizadores (no hay doble salto).
5. `can_jump()` devuelve `input_enabled and not is_carrying` (RF-03). Con arma o hacha equipada se puede saltar (RF-04).

Sin daño por caída (RF-04): no se agrega nada a `HealthComponent`.

### 2.3 Control en el aire

En el suelo se mantiene la aceleración actual. En el aire, el `weight` de la interpolación se multiplica por `air_control` (0.6), de modo que el jugador **conserva el impulso** y solo lo corrige parcialmente (RF-06, RF-15).

El **sprint se conserva en el aire**: `get_target_speed` se evalúa igual que en el suelo, pero la velocidad horizontal ya alcanzada no se reduce de golpe al soltar Shift.

### 2.4 Sprint (ajustes a lo existente)

- Mantener: `Input.is_action_pressed(&"sprint")` ya cumple RF-10.
- Hacia atrás: hoy solo corre con `move_input.y < -0.1`. Se mantiene y se lee de `allow_backward_sprint` (RF-12).
- Cargando: ya devuelve `carry_speed` primero (RF-13). Sin cambios.
- Si el jugador corre y toma una caja, `acceleration/deceleration` hacen la transición suave a 3.2 m/s.

### 2.5 Cercas y límites (RF-08)

Con 1 m de salto no se pasa una cerca de recinto si la colisión mide **más de ~1.2 m**. Hay que **medir** las cercas del mapa (la envolvente del `Enclosure` está documentada en el plan 001 §3.3). Si alguna es más baja, se agrega un `StaticBody3D` de bloqueo invisible más alto en la capa `world`, **sin tocar el `.blend` ni el `.glb`** (aprobación del usuario para cualquier cambio en esos archivos).

### 2.6 Efectos y sonido (RF-07)

- Sonido de despegue y aterrizaje: se reutilizan los efectos de pasos o se agregan después como assets (`docs/assets.md`).
- Movimiento de cámara al aterrizar: un pequeño `Tween` de `head.position.y` (0.05 m), multiplicado por la intensidad de reducción de movimiento de cámara de `SettingsManager` (RF-73 de la spec 002).

## 3. Decisiones técnicas

| Decisión | Motivo |
|---|---|
| Gravedad propia en `PlayerConfig` (20 m/s²) | El valor global de Godot (9.8) hace saltos flotantes. La spec lo pide configurable, y así no se afecta a otros cuerpos físicos |
| Coyote time y jump buffer | Es la práctica estándar para que el salto se sienta justo con teclado y gamepad. Ambos son configurables y se pueden poner en 0 |
| Botón de salto del gamepad: **B / Círculo** | **A / Cruz ya es `interact`**. Si el mismo botón hiciera ambas cosas, al estar frente a una caja o un comedero se saltaría y se interactuaría a la vez. Pendiente de confirmación (spec 005, S-01) |
| Sin cambios en `PlayerCarry` | `can_jump()` solo consulta `is_carrying`, que ya existe |
| El control en el aire reduce `weight` | Es la forma más simple de conservar el impulso sin duplicar la lógica de movimiento |

## 4. Fases de implementación

| Fase | Contenido | Resultado verificable |
|---|---|---|
| **A** | Input map (`jump`) y `PlayerConfig` con sus valores | La acción aparece en el editor y los valores se ven en el `.tres` |
| **B** | Salto con coyote time, jump buffer y bloqueo al cargar | CA-01 |
| **C** | Control en el aire, sprint conservado y retroceso desactivado | CA-02 |
| **D** | Medir cercas, agregar bloqueos si hacen falta, y caída sin daño | CA-03 |
| **E** | Glyphs, textos de controles y consejo TIP-15 (junto con la spec 002, Fases C y D) | CA-04 |
| **F** | Verificación con teclado y gamepad, y FPS | CA-05, CA-06 |

## 5. Pruebas

- **Unitarias (GUT):** `jump_velocity` para varias alturas; que `can_jump()` sea falso cargando o con `input_enabled = false`; que el coyote time y el jump buffer no permitan doble salto; velocidad objetivo caminando, corriendo y cargando.
- **Manuales:** saltar con teclado y con gamepad; intentar saltar una cerca de cada recinto; correr, saltar y soltar Shift en el aire; cargar una caja y pulsar saltar; confirmar que `jump` y `interact` no chocan en el gamepad.

## 6. Riesgos

| Riesgo | Efecto | Mitigación |
|---|---|---|
| Algunas cercas miden menos de 1.2 m | El jugador entra a un recinto saltando | Medir cada cerca (Fase D) y agregar colisión de bloqueo |
| Saltar sobre rocas o vigas del mapa | Atorarse o salir del mapa | Probar el recorrido completo del zoológico (CA-03, CA-05) |
| El navmesh de los zombis no considera el salto | Los zombis no siguen al jugador por encima de obstáculos | Es esperado: los zombis no saltan (RF-09) |
