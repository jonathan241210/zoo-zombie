# Tareas 005: Salto y sprint

**Spec:** [`specs/005-jump-and-sprint.md`](../specs/005-jump-and-sprint.md) · **Plan:** [`plans/005-jump-and-sprint.md`](../plans/005-jump-and-sprint.md)

Convenciones:

- `[ ]` pendiente · `[x]` hecha
- `[P]`: puede hacerse en paralelo con otras tareas `[P]` de la misma fase.
- Cada tarea indica los requisitos que cubre (`RF-xx`) o el criterio de aceptación con que se verifica (`CA-xx`).
- **Ninguna fase empieza sin aprobación del usuario.**
- Supuesto vigente: el salto en gamepad usa **B / Círculo** (spec 005, S-01).

---

## Fase A: Input y configuración

- [x] T-J01 [P] Agregar la acción `jump` en `project.godot`: Espacio + botón B / Círculo del joypad — RF-01, RF-21
- [x] T-J02 [P] Agregar a `PlayerConfig` los campos `jump_height`, `gravity`, `air_control`, `coyote_time`, `jump_buffer_time` y `allow_backward_sprint` — RF-02, RF-05, RF-06, RF-12
- [x] T-J03 Actualizar `config/player_config.tres` con los valores de la spec §4 — CA-06

## Fase B: Salto

- [ ] T-J04 Usar `config.gravity` en lugar de la gravedad global de Godot en `player_controller.gd` — RF-02
- [ ] T-J05 Calcular `jump_velocity = sqrt(2 * gravity * jump_height)` e implementar el salto desde el suelo, sin doble salto — RF-01, RF-02, RF-05
- [ ] T-J06 Agregar coyote time y jump buffer — RF-05
- [ ] T-J07 Bloquear el salto al cargar una caja o con `input_enabled = false` (`can_jump()`) — RF-03, RF-04
- [ ] T-J08 Pruebas GUT: `jump_velocity`, `can_jump()`, ausencia de doble salto — CA-01
- [ ] T-J09 Verificar: saltar con teclado, con gamepad y cargando una caja — CA-01

## Fase C: Aire y sprint

- [ ] T-J10 Control reducido en el aire (`air_control`) conservando el impulso horizontal — RF-06, RF-15
- [ ] T-J11 Sprint mantenido mientras se pulsa Shift, sin correr hacia atrás salvo `allow_backward_sprint`, y bloqueado al cargar — RF-10 a RF-14
- [ ] T-J12 Pruebas GUT: velocidad objetivo caminando, corriendo y cargando — CA-02
- [ ] T-J13 Verificar: correr, saltar, soltar Shift en el aire y tomar una caja corriendo — CA-02

## Fase D: Cercas, caída y efectos

- [ ] T-J14 Medir la altura de las cercas de todos los recintos y de los límites del mapa — RF-08
- [ ] T-J15 Agregar colisiones de bloqueo (sin tocar el `.blend` ni el `.glb`) donde una cerca mida menos de ~1.2 m — RF-08, CA-03
- [ ] T-J16 Confirmar que no hay daño por caída y probar aterrizajes desde alturas del mapa — RF-04
- [ ] T-J17 Movimiento de cámara al aterrizar con intensidad ligada a `SettingsManager` (reducción de movimiento) — RF-07
- [ ] T-J18 Sonido de despegue y aterrizaje, y registrarlos en `docs/assets.md` si son externos — RF-07

## Fase E: Controles y textos

- [ ] T-J19 [P] Registrar `jump` en `InputGlyphs` y en la pantalla de Controles — RF-20, CA-04
- [ ] T-J20 [P] Agregar las claves de traducción (`ACTION_JUMP`) en español e inglés — RF-20
- [ ] T-J21 Consejo TIP-15 ("Corre con [Shift], salta con [Espacio].") y texto de Cómo jugar — RF-22

## Fase F: Verificación

- [ ] T-J22 Recorrer el mapa completo saltando y corriendo, sin atorarse ni salir del mapa — CA-03, CA-05
- [ ] T-J23 Comprobar que `jump` e `interact` no chocan en gamepad — CA-04
- [ ] T-J24 Medir FPS (60 FPS a 1080p) — CA-05
- [ ] T-J25 Revisar todos los criterios de aceptación CA-01 a CA-06
