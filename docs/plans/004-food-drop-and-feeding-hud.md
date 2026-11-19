# Plan técnico 004: Soltar comida y HUD de alimentación

**Estado:** Soltar, HUD jugador, barra vida/saciedad y alimentación por vida aprobados · **Versión:** 0.4 · **Fecha:** 2026-11-19
**Spec:** [`specs/004-food-drop-and-feeding-hud.md`](../specs/004-food-drop-and-feeding-hud.md) · **Tareas:** [`tasks/004-food-drop-and-feeding-hud.md`](../tasks/004-food-drop-and-feeding-hud.md)
**Se apoya en:** [`plans/001-zoo-survival.md`](001-zoo-survival.md) (`PlayerCarry`, `Feeder`, `FoodCrateDirector`, `Animal`) y [`plans/002-menus-and-onboarding.md`](002-menus-and-onboarding.md) (`InputGlyphs`, consejos, controles).

---

## 1. Estado actual del código y dependencias

| Elemento | Estado | Consecuencia |
|---|---|---|
| `PlayerCarry` (`ARMED` / `CARRYING`) | Hecho. Tiene `pick_up()` y `consume()`; no tiene `drop()` | Se agrega `drop()` |
| `PlayerInteractor` | Hecho. Busca el mejor `Interactable` cercano y lo activa con `interact` | Se agrega el respaldo "soltar" cuando no hay nada que activar |
| `FoodCrate` (`food_crate.gd`) | Hecho. Se recoge y se libera con `queue_free()`; emite `picked_up` | Las cajas soltadas deben poder recogerse sin generar reaparición |
| `FoodCrateDirector` | Hecho. Cuenta cajas activas por punto de aparición (`_occupied`) | Hay que contar también las cajas sueltas (RF-04) |
| `Feeder` | Hecho. Se asocia al animal y valida `is_carrying` y `can_be_fed()` | Se agrega el contador 3D |
| `Animal` | Tiene estados, `feed()` y `HealthComponent`; integra `AnimalNeeds` para saciedad, daño por hambre y muerte |
| `AnimalConfig` | Ya tiene `grace_period` (30 s) y `starvation_damage_per_second` | No hace falta un campo nuevo para la duración |
| HUD (tarjetas de animales) | **No existe** (Fase 9 de la 001) | Las barras del HUD (RF-10) esperan a T-091 y T-092 |
| Indicadores del jugador | Ahora existe `PlayerStatusHud` con barra de vida y cargador/reserva; no cubre aún el HUD completo RF-100 | Se conecta a `HealthComponent` y `EventBus.ammo_changed` |
| Input map | `interact` existe (E + A / Cruz) | No se agrega ninguna acción nueva (RF-40) |

> [!IMPORTANT]
> Las barras flotantes y el contador completo de saciedad siguen pendientes. La barra próxima aprobada usa el contorno amarillo como lectura de saciedad; no agrega una segunda barra.

## 2. Arquitectura

### 2.1 Soltar la caja (RF-01 a RF-09)

**`PlayerCarry.drop()`**: si está `CARRYING`, instancia `food_crate.tscn` en el primer punto libre frente al jugador (rayos a pared y suelo), registra la caja en `FoodCrateDirector`, pasa a `ARMED` y emite `crate_dropped`. Es el opuesto de `consume()`, pero **no** alimenta.

**Prioridad de E (RF-05)** en `PlayerInteractor._unhandled_input`:

```
interact pulsado:
  si hay un Interactable enfocado y puede activarse → activarlo (alimentar o recoger)
  si no, y el jugador está CARRYING                 → carry.drop()
```

Así, junto a un comedero donde se puede alimentar, E alimenta. Si el comedero no aplica (animal muerto o escapado), el `validator` devuelve falso y E suelta la caja.

La acción enfocada solo consume el evento si `Interactable.interact()` devuelve `true`. Si devuelve `false` (por ejemplo, el foco quedó obsoleto tras cambiar el estado), se intenta el respaldo de soltar. De este modo no se pierde la pulsación entre la validación del foco y el manejo del evento.

**`DroppedCrate`**: no se crea una escena nueva. Se reutiliza `food_crate.tscn` (la misma caja del mapa) con un modo "suelta":

| Propiedad | Caja de aparición | Caja soltada |
|---|---|---|
| `spawn_point` | Un `Marker3D` | Ninguno |
| Al recogerla | Emite `picked_up` y el director programa reaparición | Emite `picked_up`, **sin** reaparición |
| Duración | Permanente hasta recogerla | Permanente (RF-03) |

`FoodCrate` gana `var is_dropped: bool` y `RigidBody3D`/colisión opcional: se coloca con un `PhysicsRayQuery` hacia adelante (RF-06) y otro hacia abajo para encontrar el suelo. Si el rayo frontal choca con geometría, se coloca justo antes del punto de choque.

**`FoodCrateDirector`**: mantiene un registro de cajas sueltas. `active_count()` pasa a ser `_occupied.size() + _dropped_crates.size()`. Al recoger una caja suelta se quita del registro y **no** se programa reaparición, porque el punto original ya reaparece solo (RF-04). El director no genera nuevas cajas mientras `active_count() >= max_active`.

**Efectos secundarios:**
- Animación y sonido (RF-07): `ViewModel` ya oculta los brazos y muestra la caja al cargar. Se agrega un `Tween` corto (`drop_time`, 0.3 s) que baja la caja y la oculta, y bloquea el disparo durante ese tiempo con un `_is_dropping` en `PlayerCarry`.
- Atracción (RF-09): al emitirse `player_carry_changed(false)`, el sistema `AnimalLure` (T-074 de la 001, aún sin hacer) deja de seguir al jugador. No requiere código extra aquí.
- Muerte del jugador (RF-14 de la 001): sigue **perdiendo** la caja sin soltarla. Es un caso distinto y no cambia.

### 2.2 Indicadores básicos del jugador (RF-50)

`PlayerStatusHud` se agrega al `CanvasLayer` existente. Presenta vida actual/máxima con una barra y cargador/reserva de munición. Escucha `HealthComponent.health_changed` y `EventBus.ammo_changed`; consulta los valores actuales al iniciar para no depender de señales previas a su carga. El HUD completo (oleada, puntaje, temporizador y tarjetas de animales) queda para T-091/T-092 de la spec 001.

### 2.2.1 Vida y saciedad de animales cercanos en el HUD (RF-60 a RF-64)

Una escena `AnimalHealthHud` escucha `EventBus.animal_registered`, crea una fila para cada `Animal` y actualiza su visibilidad según la distancia al jugador. Las filas se apilan justo encima de `PlayerStatusHud` y muestran un corazón más una barra compacta independiente por animal.

Cada fila conecta `HealthComponent.health_changed` y `AnimalNeeds.satiety_changed`; el `ProgressBar` interior usa relleno verde y su valor es exclusivamente la proporción de vida actual. Un `Control` de borde se dibuja aparte alrededor de la barra. Su color interpola suavemente de amarillo intenso a oliva apagado según la saciedad actual y vuelve a intenso al alimentar. No representa una segunda barra y no depende de la vida.

Los valores de radio, tamaño, grosor y colores viven en `AnimalHealthHudConfig`. La lógica temporal y el daño por hambre viven en `AnimalNeeds` (Fase 4 de la spec 001), no en el HUD.

### 2.3 Saturación (RF-20 a RF-23)

La saturación es el **periodo de gracia** de `AnimalNeeds` (T-040). No hay un segundo temporizador.

`AnimalNeeds` (lógica pura, sin nodos) expone:

| Miembro | Descripción |
|---|---|
| `satiety_remaining: float` | Segundos restantes de gracia |
| `satiety_ratio() -> float` | `satiety_remaining / grace_period` (0 a 1) |
| `signal satiety_changed(ratio, seconds_left)` | Se emite continuamente al bajar la saciedad y al alimentar |
| `feed()` | Reinicia `satiety_remaining = grace_period` |
| `tick(delta)` | Baja la saciedad y devuelve el daño de hambre que corresponda al llegar a 0 |

`AnimalNeeds` es lógica pura (`RefCounted`) y `Animal._physics_process()` avanza el temporizador, así se pausa con el árbol y sigue avanzando durante el resto de la partida. La duración se lee de `AnimalConfig.grace_period` (RF-20). El temporizador empieza lleno al inicio.

Al alimentar, `Animal` cura solo si le falta vida y siempre llama `needs.feed()`. El comedero cambia a `FULL`; `AnimalNeeds` emite `satiety_depleted` al vaciarse y el comedero pasa a `EMPTY`.

### 2.4 Contador en el comedero (RF-30 a RF-37)

`Feeder` gana un hijo `FeederTimer` (`Label3D`):

| Propiedad | Valor |
|---|---|
| `billboard` | `BILLBOARD_ENABLED` |
| `no_depth_test` | `true` (legible a distancia) |
| `outline_size` | Configurable (`FeedingHudConfig`) |
| `pixel_size` / `font_size` | Configurables |
| Posición | Sobre el comedero; para el comedero elevado de la jirafa, sobre el soporte |

`FeederTimer` se conecta a `animal.needs.satiety_changed`:

- Texto: `tr("FEEDER_SECONDS").format({s = seconds_left})`, por ejemplo `27 s`.
- Rojo y parpadeo cuando `seconds_left < urgent_threshold` (10 s). El parpadeo es un `Tween` de `modulate:a`.
- `0 s` en rojo cuando la saturación está agotada (RF-33).
- Se oculta con `visible = false` cuando el animal escapa (`animal_escaped`) o muere (`animal_died`); aparece de nuevo en `Feeder.attach()` cuando el animal es contenido (RF-35).

### 2.5 Barras de vida y saturación sobre el animal (RF-11 a RF-15)

Nueva escena `scenes/ui/world/animal_bars.tscn` (`Node3D`, hijo del animal):

```
AnimalBars (Node3D, script animal_bars.gd)
├── HealthBar (Sprite3D billboard + SubViewport o TextureProgressBar vía ShaderMaterial)
└── SatietyBar (igual, debajo)
```

Para evitar un `SubViewport` por barra (costo de render), cada barra es un `MeshInstance3D` con un `QuadMesh` y un **shader simple** (`bar.gdshader`) con los uniforms `ratio`, `fill_color` y `back_color`. El billboard se activa con `billboard_mode` del `StandardMaterial3D`, o en el shader con `MODELVIEW_MATRIX`. Es una sola draw call por barra y se actualiza por `set_shader_parameter("ratio", x)`.

- Vida: verde. Por debajo de `weak_threshold` pasa a rojo (RF-12). Se calcula con `HealthComponent.health_changed`.
- Saturación: amarillo. Se actualiza con `AnimalNeeds.satiety_changed`. Parpadea al llegar a 0 (RF-13).
- Visibilidad: se oculta a más de `bars_visible_distance` (25 m) de la cámara, comparando la distancia en `_process` a baja frecuencia (cada 0.1 s). Se oculta si el animal murió (RF-14).
- Accesibilidad (RF-15): cada barra lleva un icono (corazón y hoja) a la izquierda, además del color.

### 2.6 Tarjeta del HUD (RF-10)

Depende de T-091 y T-092 de la 001. Cuando exista `AnimalCard`, usa los mismos colores de `FeedingHudConfig` (`health_color` verde, `satiety_color` amarillo) para sus `ProgressBar`, con `StyleBoxFlat` creados desde el recurso. Se agrega la lectura numérica de segundos. Si el HUD aún no existe al implementar esta spec, la tarea se aplaza hasta la Fase 9 de la 001.

### 2.6 Recurso de configuración

`scripts/data/feeding_hud_config.gd` y `config/feeding_hud_config.tres`:

| Campo | Valor inicial |
|---|---|
| `health_color` | verde (por ejemplo `#4CAF50`) |
| `health_low_color` | rojo (`#E53935`) |
| `satiety_color` | amarillo (`#FFC107`) |
| `timer_color` / `timer_urgent_color` | blanco / rojo |
| `timer_urgent_threshold` | 10.0 s |
| `bars_visible_distance` | 25.0 m |
| `timer_font_size` / `timer_outline_size` | 64 / 12 |
| `drop_time` (en `PlayerConfig`) | 0.3 s |

### 2.7 Controles y textos (RF-40 a RF-43)

- No hay acción nueva: se reutiliza `interact`.
- `InputGlyphs` ya muestra el icono de `interact` en el aviso. La clave `PROMPT_DROP` ("Soltar") se muestra cuando se carga una caja y no hay un comedero aplicable; la decide `InteractionPrompt` (ya existe) consultando `PlayerCarry`.
- Textos en el CSV: `PROMPT_DROP`, `FEEDER_SECONDS`, `HOWTO_DROP`, `TIP_DROP_CRATE` (TIP-14), y el cambio de la fila de controles "Interactuar (recoger, alimentar, soltar)".
- Consejo TIP-14 en `config/tips/tip_catalog.tres`, con el disparador `CARRY_STARTED` (ya existe en el plan 002).

### 2.8 Archivos

```
scripts/
├── player/player_carry.gd        # + drop(), señal crate_dropped, _is_dropping
├── player/player_interactor.gd   # + respaldo "soltar" con E
├── pickups/food_crate.gd         # + is_dropped, sin reaparición
├── world/food_crate_director.gd  # + _dropped y conteo
├── world/feeder.gd               # + FeederTimer
├── animals/animal_needs.gd       # NUEVO (T-040 de la 001): saturación y hambre
├── ui/world/animal_bars.gd       # NUEVO
├── ui/world/feeder_timer.gd      # NUEVO
├── data/feeding_hud_config.gd    # NUEVO
├── data/animal_health_hud_config.gd # NUEVO: radio, dimensiones y desgaste del borde
├── ui/animal_health_hud.gd       # NUEVO: filas próximas, seguimiento de vida/distancia
├── ui/animal_health_indicator.gd # NUEVO: corazón, relleno verde y borde amarillo
scenes/ui/world/animal_bars.tscn  # NUEVA
shaders/bar.gdshader              # NUEVO
config/feeding_hud_config.tres    # NUEVO
config/animal_health_hud_config.tres # NUEVO
tests/test_animal_needs.gd        # NUEVO
tests/test_food_crate_director.gd # + casos de cajas soltadas
tests/test_player_carry.gd        # + drop()
```

## 3. Decisiones técnicas

| Decisión | Motivo |
|---|---|
| Soltar es el **respaldo** de `interact` cuando no hay nada que activar | Cumple RF-05 sin mapear una tecla nueva, y no choca con alimentar |
| La caja soltada **reutiliza** `food_crate.tscn` (`is_dropped`) | Evita duplicar escenas y comportamiento (AGENTS.md, §5) |
| La caja suelta cuenta para el máximo, pero **no** programa reaparición | Su punto original ya reaparece solo; así no hay cajas infinitas |
| Saturación = periodo de gracia existente | La spec lo confirma (D-03 y D-04); evita dos temporizadores desincronizados |
| Barras con `QuadMesh` + shader, no con `SubViewport` | Una draw call por barra y sin renders extra, con el máximo de zombis en pantalla (CA-15 de la 001) |
| `Label3D` con `no_depth_test` para el contador | Legible a distancia y a través de la cerca; se traduce con `tr()` |
| Colores y umbrales en `FeedingHudConfig` | Principio III de la constitución: todo valor de diseño vive en `.tres` |

## 4. Fases de implementación

| Fase | Contenido | Depende de | Resultado verificable |
|---|---|---|---|
| **A** | `PlayerCarry.drop()`, respaldo en `PlayerInteractor`, caja soltada y conteo en el director | Fase 3 de la 001 (hecha) | CA-01, CA-02, CA-03 |
| **B** | Animación y sonido de soltar, `PROMPT_DROP`, texto de controles y TIP-14 | A, spec 002 (parcial) | CA-10 (parcial) |
| **C** | `AnimalNeeds` (saturación y hambre) | T-040 a T-042 de la 001 | CA-06 |
| **D** | `FeederTimer` en cada comedero | C | CA-07, CA-08 |
| **E** | `AnimalBars` flotantes con shader | C | CA-05 (parcial) |
| **F** | Colores en la tarjeta del HUD | T-091 y T-092 de la 001 | CA-05 |
| **G** | Verificación con teclado y gamepad, y FPS | A–F | CA-04, CA-09, CA-11 |
| **H** | Indicadores compactos de vida animal en HUD con contorno amarillo que representa saciedad | Animal, HUD del jugador, `AnimalNeeds` | CA-12 a CA-15 |

> [!NOTE]
> El hambre gradual y la respuesta de alimentación de la Fase C están implementadas. El estado débil, contador, barras flotantes y verificación manual siguen pendientes. La Fase H usa el mismo `AnimalNeeds` y `HealthComponent`.

## 5. Pruebas

- **Unitarias (GUT):** `PlayerCarry.drop()` (de `CARRYING` a `ARMED`, y falso si no se carga); `FoodCrateDirector` cuenta las cajas sueltas y no programa reaparición; `AnimalNeeds` (la saturación baja, se reinicia al alimentar, llega a 0 y dispara la pérdida de vida, y se detiene en pausa); formato del contador (`27 s`).
- **Integración:** ampliar [`test_feeding_flow.gd`](../../godot_zoo-zombie/zoo-zombie-godot/tests/integration/test_feeding_flow.gd): recoger, soltar, recoger de nuevo y alimentar.
- **Manuales:** soltar contra una pared; soltar junto a un comedero con y sin animal alimentable; ver las barras y el contador a 5, 15 y 30 m; esperar a que la saturación llegue a 0 y comprobar el parpadeo rojo; verificar con gamepad.

## 6. Riesgos

| Riesgo | Efecto | Mitigación |
|---|---|---|
| El estado débil y los indicadores completos de saciedad siguen pendientes | Las tarjetas y el contador 3D no están disponibles | El `AnimalNeeds` actual alimenta el contorno del HUD; completar esos elementos en sus fases aprobadas |
| Soltar la caja dentro de un recinto o fuera del mapa | La caja queda inalcanzable | Rayos de colocación y `NavigationServer`/`world` como respaldo; si no hay suelo, se vuelve a ARMADO y la caja reaparece en su punto |
| Demasiadas cajas sueltas | Se acumulan y se saltan el máximo | Conteo en el director (RF-04) y no se genera reaparición adicional |
| Barras y textos 3D con el máximo de zombis | Bajan los FPS | Shader sin `SubViewport`, visibilidad por distancia y actualización de baja frecuencia |
