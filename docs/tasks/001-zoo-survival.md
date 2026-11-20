# Tareas 001: Supervivencia en el zoológico

**Spec:** [`specs/001-zoo-survival.md`](../specs/001-zoo-survival.md) · **Plan:** [`plans/001-zoo-survival.md`](../plans/001-zoo-survival.md)

Convenciones:

- `[ ]` pendiente · `[x]` hecha
- `[P]`: puede hacerse en paralelo con otras tareas `[P]` de la misma fase.
- Cada tarea indica los requisitos que cubre (`RF-xx`) o el criterio de aceptación con que se verifica (`CA-xx`).
- **Ninguna fase empieza sin aprobación del usuario.**

---

## Fase 1: Análisis y base técnica

**Objetivo:** caminar en primera persona por el zoológico, con colisiones, a 60 FPS.

- [x] T-001 Analizar el repositorio: motor, mapa, modelos y sistemas existentes (plan §1)
- [x] T-002 Escribir la spec, el plan, las tareas, la constitución y `AGENTS.md`
- [x] T-003 Renombrar `assets/modelos`, `assets/texturas` y `assets/audio` a inglés (`models`, `textures`, `audio`) según la regla de idioma
- [x] T-004 Crear la estructura de carpetas del proyecto Godot (plan §2.2)
- [x] T-005 Configurar el input map con teclado/mouse y gamepad, sin salto (plan §2.6) — RF-01
- [x] T-006 [P] Crear el autoload `EventBus` con todas las señales globales (plan §2.3)
- [x] T-007 [P] Crear el autoload `GameManager`: estados de la partida, tiempo, estadísticas, animales vivos y reinicio — RF-49, RF-93
- [x] T-008 [P] Crear las clases de datos `Resource` y sus `.tres` con los valores de la spec §6 — CA-13
- [x] T-009 [P] Crear el componente `HealthComponent`, con pruebas
- [x] T-010 [P] Crear el componente `Interactable`
- [x] T-011 Instalar y validar GUT (o gdUnit4) con Godot 4.7 y ejecutar una prueba headless (GUT 9.7.1)
- [x] T-012 Script `export_map.py`: exportar el mapa a GLB excluyendo las colecciones auxiliares (plan §3.3)
- [x] T-013 Agregar colisiones simplificadas al mapa (script de post-importación de Godot `zoo_map_post_import.gd`)
- [x] T-014 Optimizar la vegetación: el pasto pasa a `MultiMeshInstance3D` y los árboles y arbustos se instancian
- [x] T-015 Crear `zoo_level.tscn`: mapa, iluminación, entorno, navmesh y marcadores (jugador en la cafetería, cajas, zombis, recintos y refugios)
- [x] T-016 Crear `player.tscn`: `CharacterBody3D` en primera persona con caminar, correr y mirar — RF-01, RF-06
- [x] T-017 Crear `game.tscn` (escena raíz) y definirla como escena principal
- [x] T-018 Verificar: recorrer el mapa completo y medir FPS — CA-14 (parcial), CA-15

## Fase 2: Modelos y animaciones

**Objetivo:** todos los modelos en Godot, con sus animaciones.

- [x] T-020 [P] Crear las utilidades comunes de Blender: `lib/materials.py`, `lib/mesh_utils.py`, `lib/anim_utils.py` y `lib/export_utils.py` (además `lib/rig_prep.py`, `lib/animal_prep.py` y `lib/preview.py`)
- [x] T-021 `prepare_giraffe.py`: escala, nombres estándar de las acciones, nuevas acciones `death` y `weak` y exportación — RF-110, RF-111, RF-113
- [x] T-022 `prepare_elephant.py`: lo mismo para el elefante — RF-110, RF-111, RF-113
- [x] T-023 [P] `prepare_zombie.py`: escala, nombres estándar (`walk`, `run`, `attack`, `hit`, `death`, `idle`) y exportación — RF-67
- [x] T-024 `prepare_fp_arms.py`: quitar las animaciones de otras herramientas y renombrar (`shotgun_idle`, `shotgun_fire`, `shotgun_draw`, `axe_idle`, `axe_swing` a partir de `E_Martillo`) — RF-111, RF-113. La recarga se hace por código en T-052 y el transporte de la caja en T-034 (ver plan §1.4)
- [x] T-024b [P] Preparar `hacha.glb`: escala, origen en el mango, texturas reducidas y exportación — RF-5A
- [x] T-025 [P] `models/giraffe_feeder.py`: comedero elevado sobre poste — RF-24
- [x] T-026 [P] `models/elephant_feeder.py`: comedero bajo — RF-24
- [x] T-027 [P] `models/food_crate.py` y `models/ammo_box.py` — RF-112
- [x] T-028 Crear la variante `weak` para ambos animales (se hizo en Blender: `idle` 1.6× más lento con cuello y cabeza caídos) — RF-27, RF-111
- [x] T-029 Verificar: reproducir en Godot todas las animaciones de cada modelo y comparar escalas lado a lado
- [x] T-030 Registrar autor, fuente y licencia de cada modelo en `docs/assets.md`

## Fase 3: Alimentación y transporte de cajas

- [x] T-031 Crear `food_crate.tscn` + `food_crate.gd` (`Interactable`: recoger) — RF-11
- [x] T-032 Crear `food_crate_spawn.tscn` + coordinador de reaparición y máximo de cajas activas — RF-10, RF-13
- [x] T-033 Crear `PlayerCarry` con los estados `ARMED`/`CARRYING`, velocidad reducida y una sola caja — RF-04, RF-05, RF-12
- [x] T-034 Viewmodel de transporte: brazos ocultos y caja frente a la cámara con balanceo procedural al caminar — RF-03, RF-05
- [x] T-035 Crear `Feeder` (`Interactable`: alimentar si `CARRYING` y el animal está contenido) — RF-25
- [x] T-036 Crear `Enclosure` (sin daño todavía) + `EnclosureRegistry`; colocar a la jirafa, al elefante y sus comederos; paseo dentro del recinto — RF-20, RF-24
- [x] T-037 Hacer que la caja se pierda al morir el jugador — RF-14
- [x] T-038 Verificar — CA-01, CA-03

## Fase 4: Hambre, debilidad y muerte de los animales

- [x] T-040 Crear `AnimalNeeds` con saciedad completa inicial, vaciado continuo y daño gradual al agotarse — RF-21 a RF-23
- [x] T-041 Integrar alimentación: curar solo con vida incompleta y reiniciar siempre la saciedad — RF-25
- [x] T-042 Pausar el temporizador al pausar la partida y emitir cambios para el HUD — RF-23, RF-108
- [x] T-043 Emitir la muerte antes de eliminar el animal y su comedero tras la animación; `GameManager` actualiza la derrota — RF-29, RF-47 a RF-49
- [x] T-044 Implementar y verificar el estado `WEAK`, animación y movimiento más lento — RF-27 (modificador sobre los estados de movimiento: `is_weak`, `weak_speed_multiplier`, animación `weak` en reposo, señal `animal_weak_changed` y alerta roja «Débil» en la fila de vida del HUD)
- [x] T-045 Impedir que la escopeta del jugador dañe a la jirafa — RF-28
- [x] T-046 Publicar estados `EMPTY` / `FULL` del comedero para conectar las visuales — spec 006
- [ ] T-047 Verificación manual: hambre, curación, daño gradual, inmunidad y desaparición — CA-17 a CA-20 (cubierto por `tests/integration/test_animal_lifecycle.gd`; falta la revisión visual del usuario en el juego)

## Fase 5: Combate, escopeta y munición

- [x] T-050 Crear `AmmoState` (lógica pura) con pruebas — RF-51, CA-12 (`tests/test_ammo_state.gd`)
- [x] T-051 Crear `shotgun.gd`: hitscan con N perdigones, dispersión, alcance y cadencia — RF-50, RF-54
- [x] T-052 Recarga procedural con Tween y duración configurable — RF-52
- [x] T-053 Agregar feedback: fogonazo, retroceso de cámara, sonido e impacto — RF-53 (sonido provisional generado con `tools/generate_sfx.py`)
- [x] T-054 Bloquear el disparo y la recarga en `CARRYING` — RF-05
- [x] T-055 Crear `ammo_pickup.tscn`: recogida automática hasta el máximo y desaparición por tiempo — RF-56, RF-57 (los cartuchos que no caben se quedan en la caja)
- [x] T-056 Crear `WeaponManager`: cambio entre escopeta y hacha, bloqueo en `CARRYING` y restaurar el arma después de alimentar — RF-5B, RF-05
- [x] T-057 Crear `axe.gd`: golpe en arco, máximo de zombis por golpe, cadencia, retroceso y feedback — RF-5A, RF-5C (golpe procedural en el viewmodel; el retroceso llama a `apply_knockback()` del objetivo, que el zombi implementa en la Fase 6)
- [x] T-058 Colocar 15 marcadores `AmmoSpawnPoint` en lugares poco obvios del mapa — RF-59 (`Markers/AmmoSpawns`, validados con rayos de suelo y sin choques con estructuras)
- [x] T-059 Crear `AmmoSpawnDirector`: selección aleatoria, cajas activas, reaparición en otro punto, y luz con pulso y material emisivo — RF-58, RF-59
- [ ] T-05A Verificar — CA-12 (parcial), CA-16 (automático en `tests/integration/test_weapons.gd` y `tests/test_ammo_spawn_director.gd`; falta la prueba del usuario jugando)

## Fase 6: IA de los zombis (cazadores) y muerte del jugador

- [x] T-060 Crear `zombie.tscn`: `CharacterBody3D` + `NavigationAgent3D` + `HealthComponent` + `Hurtbox`. Sincronizar la velocidad de las animaciones con el movimiento: el clip `walk` del zombi corresponde a ~0.55 m/s y `run` a ~1.95 m/s (medido), así que con 2.5 m/s hay que usar `run` o escalar la reproducción (`scenes/enemies/zombie.tscn`; modelo girado 180° porque mira a +Z; persigue con `run` escalado a la velocidad real. Sin `Hurtbox` aparte: los perdigones y el hacha golpean la cápsula del cuerpo)
- [x] T-061 Máquina de estados `IDLE`/`CHASE`/`ATTACK`/`HIT`/`DEAD`, con detección por radio y línea de visión — RF-63, RF-64 (detección cada `think_interval`; los zombis de oleada aparecen ya alertados)
- [x] T-062 Ataque cuerpo a cuerpo, incluso cuando el jugador carga una caja — RF-65
- [x] T-063 Muerte, probabilidad de soltar munición y desaparición del cuerpo — RF-55, RF-66, RF-68 (el cuerpo deja de bloquear y desaparece tras `corpse_lifetime`; también recibe `apply_knockback()` del hacha)
- [x] T-064 Muerte y reaparición del jugador en la cafetería con penalización — RF-80 a RF-83 (cámara cae al suelo; la penalización de puntaje llega con `ScoreManager` en T-090)
- [ ] T-065 Verificar — CA-08, CA-11 (automático en `tests/integration/test_zombies.gd`; falta la prueba del usuario jugando. Mientras no haya oleadas, `ZombieSpawner.test_zombie_count = 4` en `game.tscn` crea zombis al empezar)

## Fase 7: Recintos destructibles, escape y recaptura

- [x] T-070 Dar integridad (`HealthComponent`) a `Enclosure`, con puntos de ataque exteriores y estado destruido permanente — RF-30 a RF-32, RF-35 (la cerca deja de colisionar y se hunde en el suelo; puntos de ataque sobre el navmesh fuera de la cerca)
- [x] T-071 Crear `ZombieTargetSelector`: roles cazador / destructor, cambio de objetivo del destructor y prioridad sobre animales escapados — RF-60 a RF-62
- [x] T-072 Crear `Stamina` (lógica pura) con pruebas — RF-41, RF-42 (`scripts/components/stamina.gd`, `tests/test_stamina.gd`)
- [x] T-073 Estados del animal escapado: `FLEEING` (huye de los zombis) y `TIRED` — RF-33, RF-40 a RF-43 (también `ESCAPING` (sale por la cerca rota) y `LOOSE` (libre sin amenaza))
- [x] T-074 Crear `AnimalLure`: seguir al jugador que carga una caja, con radio de atracción y radio máximo — RF-44 (integrado en `Animal` en lugar de un nodo `AnimalLure` aparte)
- [x] T-075 Recaptura: el área interior de un refugio libre asigna el animal al recinto y le mueve el comedero — RF-34, RF-45 (el registro revisa cada 0.25 s si un animal que sigue al jugador llega a menos de `recapture_radius` de la cerca de un refugio libre; entonces queda adentro junto a ese punto. Se agregaron anclajes de comedero a los 3 refugios)
- [x] T-076 Zombificación: horda extra en la posición del animal muerto — RF-47, RF-75
- [x] T-077 Escena de prueba: recinto bajo ataque → escape → recaptura (como prueba de integración `tests/integration/test_escape_and_recapture.gd` sobre la partida real)
- [x] T-079 Navegación de animales consciente del entorno: que busquen rutas alrededor de rocas, refugios y vigas (navmesh por recinto con su propio radio de agente + `NavigationAgent3D` con evasión), en lugar de caminar en línea recta y reintentar al atorarse. Se reutiliza para huir y seguir al jugador (petición del usuario, 2026-11-17) (parcial: el animal escapado usa `NavigationAgent3D` sobre el navmesh global para huir y seguir; el paseo dentro del recinto sigue con puntos libres y barrido de esfera)
- [ ] T-078 Verificar — CA-04, CA-05, CA-06, CA-07 (automático en las pruebas de integración; falta la prueba del usuario jugando)

## Fase 8: Oleadas y temporizadores

- [x] T-080 Crear `WaveSchedule` (lógica pura) con pruebas: oleada → descanso → oleada — RF-70 a RF-73 (`scripts/systems/wave_schedule.gd`, `tests/test_wave_schedule.gd`)
- [x] T-081 Crear `WaveManager` + `ZombieSpawner`: puntos del perímetro, intervalo, máximo de vivos, proporción de destructores y multiplicadores — RF-71, RF-74 (los zombis aparecen en puntos del perímetro a más de `min_spawn_distance` del jugador; se quitaron los zombis de prueba de la Fase 6)
- [x] T-082 Hacer que los zombis vivos persistan entre oleadas — RF-72
- [x] T-083 Al terminar la oleada 3 con al menos un animal vivo → `game_won` — RF-76
- [ ] T-084 Verificar — CA-09, CA-10 (automático en `tests/integration/test_waves.gd` con tiempos acortados; falta la prueba del usuario jugando y la pantalla de victoria de T-095)

## Fase 9: HUD, puntuación y pantallas

- [ ] T-090 Crear `ScoreManager` con pruebas — RF-90 a RF-93
- [ ] T-091 Crear el HUD base: vida, munición, puntaje, oleada, tiempo e indicador de carga — RF-100
- [x] T-091a Mostrar vida actual/máxima y munición del jugador — RF-100, RF-109 (HUD parcial; T-091 sigue pendiente para los demás elementos)
- [ ] T-092 Agregar tarjetas de los animales: barras de vida, alimento e integridad del recinto, y estado — RF-101, RF-108
- [ ] T-097 Agregar icono del arma equipada, munición (`cargador / reserva` o `∞` con el hacha) y alerta de munición baja — RF-109
- [x] T-098 Agregar contador de zombis vivos y por aparecer; `WaveManager` emite `zombie_count_changed(alive, pending)` por `EventBus` — RF-10A (`scenes/ui/wave_hud.tscn`: oleada N/3, tiempo de la fase, zombis vivos y por aparecer; cuenta regresiva y descanso)
- [ ] T-093 Agregar indicaciones contextuales con icono según el dispositivo — RF-102
- [ ] T-094 Agregar avisos (oleada, descanso, recinto atacado o destruido, animal muerto) y marcadores hacia los animales escapados y los refugios — RF-103, RF-104
- [ ] T-095 Crear las pantallas de victoria y derrota, y el menú de pausa — RF-105 a RF-107
- [x] T-099 Mensajes de acción: `ActionFeed`, `ActionFeedConfig`, señales nuevas en `EventBus` y textos en el CSV, con pruebas — RF-10B, CA-21 (se adelanta a pedido del usuario) (`scenes/ui/action_feed.tscn`, `config/action_feed_config.tres`, `tests/integration/test_action_feed.gd`)
- [ ] T-096 Verificar — CA-10

## Fase 10: Integración, pruebas y optimización

- [ ] T-100 Jugar partidas completas con teclado/mouse y con gamepad — CA-14
- [ ] T-101 Ajustar el balance de los valores `.tres` según las pruebas
- [ ] T-102 Hacer un perfil de rendimiento con 16 zombis y optimizar (LOD, sombras, draw calls, texturas) — CA-15
- [ ] T-103 Revisar todos los criterios de aceptación CA-01 a CA-15
- [ ] T-104 Actualizar la documentación y los ADR con las decisiones finales
