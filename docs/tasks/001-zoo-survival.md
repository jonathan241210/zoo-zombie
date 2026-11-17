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
- [ ] T-003 Renombrar `assets/modelos`, `assets/texturas` y `assets/audio` a inglés (`models`, `textures`, `audio`) según la regla de idioma
- [ ] T-004 Crear la estructura de carpetas del proyecto Godot (plan §2.2)
- [ ] T-005 Configurar el input map con teclado/mouse y gamepad, sin salto (plan §2.6) — RF-01
- [ ] T-006 [P] Crear el autoload `EventBus` con todas las señales globales (plan §2.3)
- [ ] T-007 [P] Crear el autoload `GameManager`: estados de la partida, tiempo, estadísticas, animales vivos y reinicio — RF-49, RF-93
- [ ] T-008 [P] Crear las clases de datos `Resource` y sus `.tres` con los valores de la spec §6 — CA-13
- [ ] T-009 [P] Crear el componente `HealthComponent`, con pruebas
- [ ] T-010 [P] Crear el componente `Interactable`
- [ ] T-011 Instalar y validar GUT (o gdUnit4) con Godot 4.7 y ejecutar una prueba headless
- [ ] T-012 Script `export_map.py`: exportar el mapa a GLB excluyendo las colecciones auxiliares (plan §3.3)
- [ ] T-013 Agregar colisiones simplificadas al mapa (sufijos `-col` / `-colonly`)
- [ ] T-014 Optimizar la vegetación: el pasto pasa a `MultiMeshInstance3D` y los árboles y arbustos se instancian
- [ ] T-015 Crear `zoo_level.tscn`: mapa, iluminación, entorno, navmesh y marcadores (jugador en la cafetería, cajas, zombis, recintos y refugios)
- [ ] T-016 Crear `player.tscn`: `CharacterBody3D` en primera persona con caminar, correr y mirar — RF-01, RF-06
- [ ] T-017 Crear `game.tscn` (escena raíz) y definirla como escena principal
- [ ] T-018 Verificar: recorrer el mapa completo y medir FPS — CA-14 (parcial), CA-15

## Fase 2: Modelos y animaciones

**Objetivo:** todos los modelos en Godot, con sus animaciones.

- [ ] T-020 [P] Crear las utilidades comunes de Blender: `lib/materials.py`, `lib/mesh_utils.py`, `lib/anim_utils.py` y `lib/export_utils.py`
- [ ] T-021 `prepare_giraffe.py`: escala, nombres estándar de las acciones, nueva acción `death` y exportación — RF-110, RF-111, RF-113
- [ ] T-022 `prepare_elephant.py`: lo mismo para el elefante — RF-110, RF-111, RF-113
- [ ] T-023 [P] `prepare_zombie.py`: escala, nombres estándar (`walk`, `run`, `attack`, `hit`, `death`, `idle`) y exportación — RF-67
- [ ] T-024 `prepare_fp_arms.py`: quitar las animaciones de otras herramientas, renombrar (`fire`, `draw`, `carry`, `axe_swing` a partir de `E_Martillo`) y agregar la acción `reload` — RF-111, RF-113
- [ ] T-024b [P] Preparar `hacha.glb`: escala, origen en el mango, texturas reducidas y exportación — RF-5A
- [ ] T-025 [P] `models/giraffe_feeder.py`: comedero elevado sobre poste — RF-24
- [ ] T-026 [P] `models/elephant_feeder.py`: comedero bajo — RF-24
- [ ] T-027 [P] `models/food_crate.py` y `models/ammo_box.py` — RF-112
- [ ] T-028 Crear la variante `weak` en Godot (`speed_scale` bajo + cabeza baja) para ambos animales — RF-27, RF-111
- [ ] T-029 Verificar: reproducir en Godot todas las animaciones de cada modelo y comparar escalas lado a lado
- [ ] T-030 Registrar autor, fuente y licencia de cada modelo en `docs/assets.md`

## Fase 3: Alimentación y transporte de cajas

- [ ] T-031 Crear `food_crate.tscn` + `food_crate.gd` (`Interactable`: recoger) — RF-11
- [ ] T-032 Crear `food_crate_spawn.tscn` + coordinador de reaparición y máximo de cajas activas — RF-10, RF-13
- [ ] T-033 Crear `PlayerCarry` con los estados `ARMED`/`CARRYING`, velocidad reducida y una sola caja — RF-04, RF-05, RF-12
- [ ] T-034 Viewmodel: animación `carry` con la caja y la escopeta oculta — RF-03, RF-05
- [ ] T-035 Crear `Feeder` (`Interactable`: alimentar si `CARRYING` y el animal está contenido) — RF-25
- [ ] T-036 Crear `Enclosure` (sin daño todavía) + `EnclosureRegistry`; colocar a la jirafa, al elefante y sus comederos; paseo dentro del recinto — RF-20, RF-24
- [ ] T-037 Hacer que la caja se pierda al morir el jugador — RF-14
- [ ] T-038 Verificar — CA-01, CA-03

## Fase 4: Hambre, debilidad y muerte de los animales

- [ ] T-040 Crear `AnimalNeeds` (lógica pura): gracia, pérdida de vida y umbral de debilidad, con pruebas — RF-21, RF-22, RF-27
- [ ] T-041 Máquina de estados del animal (estados contenidos, `EATING`, `WEAK`, `DEAD`) integrada con `HealthComponent` — RF-27
- [ ] T-042 Hacer que el temporizador corra toda la partida y solo se pause con el juego en pausa — RF-23
- [ ] T-043 Al morir, emitir `animal_died(id, position)`; `GameManager` declara derrota si mueren ambos — RF-47 (señal), RF-48, RF-49
- [ ] T-044 Verificar — CA-02, CA-07 (parcial)

## Fase 5: Combate, escopeta y munición

- [ ] T-050 Crear `AmmoState` (lógica pura) con pruebas — RF-51, CA-12
- [ ] T-051 Crear `shotgun.gd`: hitscan con N perdigones, dispersión, alcance y cadencia — RF-50, RF-54
- [ ] T-052 Recarga con animación y duración — RF-52
- [ ] T-053 Agregar feedback: fogonazo, retroceso de cámara, sonido e impacto — RF-53
- [ ] T-054 Bloquear el disparo y la recarga en `CARRYING` — RF-05
- [ ] T-055 Crear `ammo_pickup.tscn`: recogida automática hasta el máximo y desaparición por tiempo — RF-56, RF-57
- [ ] T-056 Crear `WeaponManager`: cambio entre escopeta y hacha, bloqueo en `CARRYING` y restaurar el arma después de alimentar — RF-5B, RF-05
- [ ] T-057 Crear `axe.gd`: golpe en arco, máximo de zombis por golpe, cadencia, retroceso y feedback — RF-5A, RF-5C
- [ ] T-058 Colocar 15 marcadores `AmmoSpawnPoint` en lugares poco obvios del mapa — RF-59
- [ ] T-059 Crear `AmmoSpawnDirector`: selección aleatoria, cajas activas, reaparición en otro punto, y luz con pulso y material emisivo — RF-58, RF-59
- [ ] T-05A Verificar — CA-12 (parcial), CA-16

## Fase 6: IA de los zombis (cazadores) y muerte del jugador

- [ ] T-060 Crear `zombie.tscn`: `CharacterBody3D` + `NavigationAgent3D` + `HealthComponent` + `Hurtbox`
- [ ] T-061 Máquina de estados `IDLE`/`CHASE`/`ATTACK`/`HIT`/`DEAD`, con detección por radio y línea de visión — RF-63, RF-64
- [ ] T-062 Ataque cuerpo a cuerpo, incluso cuando el jugador carga una caja — RF-65
- [ ] T-063 Muerte, probabilidad de soltar munición y desaparición del cuerpo — RF-55, RF-66, RF-68
- [ ] T-064 Muerte y reaparición del jugador en la cafetería con penalización — RF-80 a RF-83
- [ ] T-065 Verificar — CA-08, CA-11

## Fase 7: Recintos destructibles, escape y recaptura

- [ ] T-070 Dar integridad (`HealthComponent`) a `Enclosure`, con puntos de ataque exteriores y estado destruido permanente — RF-30 a RF-32, RF-35
- [ ] T-071 Crear `ZombieTargetSelector`: roles cazador / destructor, cambio de objetivo del destructor y prioridad sobre animales escapados — RF-60 a RF-62
- [ ] T-072 Crear `Stamina` (lógica pura) con pruebas — RF-41, RF-42
- [ ] T-073 Estados del animal escapado: `FLEEING` (huye de los zombis) y `TIRED` — RF-33, RF-40 a RF-43
- [ ] T-074 Crear `AnimalLure`: seguir al jugador que carga una caja, con radio de atracción y radio máximo — RF-44
- [ ] T-075 Recaptura: el área interior de un refugio libre asigna el animal al recinto y le mueve el comedero — RF-34, RF-45
- [ ] T-076 Zombificación: horda extra en la posición del animal muerto — RF-47, RF-75
- [ ] T-077 Escena de prueba: recinto bajo ataque → escape → recaptura
- [ ] T-078 Verificar — CA-04, CA-05, CA-06, CA-07

## Fase 8: Oleadas y temporizadores

- [ ] T-080 Crear `WaveSchedule` (lógica pura) con pruebas: oleada → descanso → oleada — RF-70 a RF-73
- [ ] T-081 Crear `WaveManager` + `ZombieSpawner`: puntos del perímetro, intervalo, máximo de vivos, proporción de destructores y multiplicadores — RF-71, RF-74
- [ ] T-082 Hacer que los zombis vivos persistan entre oleadas — RF-72
- [ ] T-083 Al terminar la oleada 3 con al menos un animal vivo → `game_won` — RF-76
- [ ] T-084 Verificar — CA-09, CA-10

## Fase 9: HUD, puntuación y pantallas

- [ ] T-090 Crear `ScoreManager` con pruebas — RF-90 a RF-93
- [ ] T-091 Crear el HUD base: vida, munición, puntaje, oleada, tiempo e indicador de carga — RF-100
- [ ] T-092 Agregar tarjetas de los animales: barras de vida, alimento e integridad del recinto, y estado — RF-101, RF-108
- [ ] T-097 Agregar icono del arma equipada, munición (`cargador / reserva` o `∞` con el hacha) y alerta de munición baja — RF-109
- [ ] T-098 Agregar contador de zombis vivos y por aparecer; `WaveManager` emite `zombie_count_changed(alive, pending)` por `EventBus` — RF-10A
- [ ] T-093 Agregar indicaciones contextuales con icono según el dispositivo — RF-102
- [ ] T-094 Agregar avisos (oleada, descanso, recinto atacado o destruido, animal muerto) y marcadores hacia los animales escapados y los refugios — RF-103, RF-104
- [ ] T-095 Crear las pantallas de victoria y derrota, y el menú de pausa — RF-105 a RF-107
- [ ] T-096 Verificar — CA-10

## Fase 10: Integración, pruebas y optimización

- [ ] T-100 Jugar partidas completas con teclado/mouse y con gamepad — CA-14
- [ ] T-101 Ajustar el balance de los valores `.tres` según las pruebas
- [ ] T-102 Hacer un perfil de rendimiento con 16 zombis y optimizar (LOD, sombras, draw calls, texturas) — CA-15
- [ ] T-103 Revisar todos los criterios de aceptación CA-01 a CA-15
- [ ] T-104 Actualizar la documentación y los ADR con las decisiones finales
