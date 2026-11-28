# Plan técnico 001: Supervivencia en el zoológico

**Estado:** Fase 4, monedas, bodegas de alimento e indicador de vida aprobados; propuestas de HUD y puntos de comida documentadas para futura implementación · **Versión:** 0.7 · **Fecha:** 2026-11-23
**Spec:** [`specs/001-zoo-survival.md`](../specs/001-zoo-survival.md) · **Tareas:** [`tasks/001-zoo-survival.md`](../tasks/001-zoo-survival.md)

---

## 1. Análisis del proyecto actual (Fase 1)

Revisión hecha el 2026-11-16.

### 1.1 Motor y herramientas

| Elemento | Estado |
|---|---|
| Motor | **Godot 4.7.2** (Steam), renderizador Forward+, física **Jolt** |
| Proyecto Godot | `godot_zoo-zombie/zoo-zombie-godot/`: recién creado, solo tiene `project.godot` e `icon.svg` |
| Blender | **5.3.0** (Steam) |
| MCP | Blender (`mcp-for-blender` 2.0) y Godot (`@coding-solo/godot-mcp`) conectados |

### 1.2 Sistemas existentes en Godot

No existe ningún sistema: ni movimiento, armas, enemigos, navegación, vida, escenas, scripts ni ADR previos. La arquitectura se define desde cero en este plan.

### 1.3 Mapa: `blender_zoo-zombie/mapacompleto_2_sin_entorno.blend`

- **Tamaño:** ~166 × 177 m (X de -76.6 a 89.8, Y de -92.6 a 84.2), altura máxima de 11.6 m. Unidades métricas, escala 1.0.
- **Objetos:** 980 (935 mallas, 33 textos, 9 curvas, 2 cámaras, 1 luz).
- **Triángulos:** ~998 000 en total, de los cuales **~630 000 son vegetación** (500 mechones de pasto, 151 arbustos y 106 árboles). **Hay que optimizar** (ver 3.2).
- **Colecciones:** `01_BASE_TERRENO`, `03_CAMINOS`, `04_VEGETACION`, `05_ESTRUCTURAS`, `06_RECINTOS` (16 recintos), `06D_HABITAT_DESIERTO`, `06Z_RECINTOS_ANTERIORES_OCULTOS` (ocultos), `07_DETALLES`, `08_PERIMETRO` y `10_ILUMINACION`.
- **Materiales:** colores planos, sin texturas de imagen.
- **Ubicaciones clave** (coordenadas de Blender, Z arriba):

| Objeto | Posición (x, y) | Tamaño | Uso en el juego |
|---|---|---|---|
| `REC_HEX_CENTRAL` | (-11.2, -3.2) | 16 × 14 m | **Recinto de la jirafa** (hexágono abierto) |
| `REC_RECINTO_ESTE` | (52.5, 12.9) | 14 × 10 m | **Recinto del elefante** (jaula abierta con alberca) |
| `REC_RECINTO_NORTE_CENTRAL` | (16.8, -31.3) | 11 × 8 m | Refugio |
| `REC_JAULA_NORTE_2` | (-47.7, 3.3) | 10 × 6 m | Refugio |
| `REC_HEX_SUR_5` | (-10.0, -55.3) | 12 × 10 m | Refugio |
| `EST_CAFETERIA` | (19.3, -8.7) | 11 × 9 m | Aparición del jugador |
| `EST_ENTRADA_PORTICO` | (-9.8, 64.4) | 18 × 3 m | Candidato para aparición de zombis |
| `EST_TIENDA`, `EST_VETERINARIA` | ubicaciones existentes | — | Dos bodegas de alimento; ambas quedan a más de 45 m del recinto más cercano y a más de 55 m del punto de aparición |

La distancia entre la jirafa y el elefante es de ~66 m.

> Los recintos `REC_RECINTO_RUSTICO_M*` son **galpones cerrados** (paredes sólidas y techo de ~3.2 m), así que no sirven para animales visibles. Se descubrió en la Fase 3 y se cambió a recintos abiertos (spec D-02, D-06, S-01).

### 1.4 Modelos descargados (`assets/models/`)

| Archivo | Rig | Animaciones incluidas | Uso |
|---|---|---|---|
| `girafa_animada.glb` (9.9 MB) | ✅ | `01_Idle_Ruminating` 8 s, `02_Walk` 4.1 s, `03_Run_Gallop` 1.8 s, `04_Eat_Browsing` 10 s, `05_Attack_Kick` 6 s | **Jirafa**. Faltan **weak** y **death** |
| `elefante_animado.glb` (8.3 MB) | ✅ | `01_Idle` 10 s, `02_Walk` 3.6 s, `03_Run` 1.7 s, `04_Eating` 10 s, `05_Attack` 6 s | **Elefante**. Faltan **weak** y **death** |
| `animation_zombie_2.glb` (3.0 MB) | ✅ | `idle01/02`, `walk01/02`, `run`, `attack01/02`, `damage`, `death`, `down`, `caution`, `eat`, `on_all_four_*` | **Zombi**. Completo |
| `brazo_escopeta.glb` (1.4 MB) | ✅ | `D_Escopeta` (disparo), `E_Escopeta` (sacar), `P_Escopeta` (pose), `E_Caja` / `P_Caja` (sostener caja), `E_Agarrar` (agarrar) y otras herramientas | **Brazos en primera persona**. Falta **reload** |
| `escopeta.glb` | ❌ | — | Escopeta estática: sirve como prop o pickup |
| `hacha.glb` (3.5 MB) | ❌ | — | **Hacha** (arma secundaria). Va sujeta a la mano del rig de brazos; el golpe usa `E_Martillo` |
| `brazos_ametralladora.glb` | ✅ | `Draw`, `Fire`, `Reload`, `Reload_Empty`, `Holster` | Reservado para un arma futura. Sirve como referencia para la animación de recarga |
| `zombie_dog_animation.glb` | ✅ | `idle`, `walk`, `run`, `attack 3`, `hit 2`, `Jump Edit` | Reservado para un enemigo futuro |
| `mad_zombie.glb` | ❌ | — | Ya no se usa: lo reemplaza `animation_zombie_2` |
| `low_poly_animals.glb` | ❌ | — | Ya no se usa: solo como referencia |

**Animaciones faltantes y cómo se resuelven:**

| Animación | Solución |
|---|---|
| Jirafa y elefante: `weak` | ✅ En Blender (`lib/rig_prep.add_weak_action`): copia de `idle` 1.6× más lenta, con cuello y cabeza caídos |
| Jirafa y elefante: `death` | ✅ En Blender (`lib/rig_prep.add_death_action`): se doblan las patas, el cuerpo cae de lado y queda apoyado en el suelo (2.25 s) |
| Brazos: `reload` | En Godot, por código (Fase 5, T-052): Tween sobre el viewmodel y el nodo de la corredera (`Corredera`), que es un nodo aparte en el GLB |
| Transporte de caja | El rig de brazos tiene **un solo brazo** (derecho) y sus poses de "caja" no se ven creíbles. Al cargar comida se ocultan los brazos y la caja se muestra frente a la cámara con balanceo procedural (Fase 3, T-034) |

---

## 2. Arquitectura propuesta

### 2.1 Principios aplicados

- **Composición por componentes:** vida, interacción, hurtbox y resistencia son nodos reutilizables.
- **Datos separados de la lógica:** todo valor de balance vive en `Resource` personalizados (`.tres`).
- **Comunicación por señales:** un autoload `EventBus` reúne los eventos globales del juego.
- **Máquinas de estado simples** (`enum` + `match`) para el jugador, los zombis y los animales.
- **Lógica pura separada de los nodos**, para poder probarla: `AnimalNeeds`, `Stamina`, `AmmoState` y `WaveSchedule`.
- **GDScript con tipado estático**, `class_name` en los scripts reutilizables.

### 2.2 Estructura del proyecto Godot

```
zoo-zombie-godot/
├── project.godot
├── addons/                      # third-party plugins (e.g. GUT for tests)
├── assets/
│   ├── models/{animals,zombies,weapons,props,map}/   # game-ready .glb
│   ├── audio/{sfx,music}/
│   └── ui/
├── config/                      # balance data (.tres)
│   ├── player_config.tres
│   ├── shotgun_config.tres
│   ├── axe_config.tres
│   ├── ammo_spawn_config.tres
│   ├── zombie_config.tres
│   ├── enclosure_config.tres
│   ├── animals/{giraffe_config.tres, elephant_config.tres}
│   ├── food_crate_config.tres
│   ├── score_config.tres
│   └── waves/{wave_1.tres, wave_2.tres, wave_3.tres}
├── scenes/
│   ├── main/game.tscn           # root: level + player + managers + HUD
│   ├── levels/zoo_level.tscn    # map + navmesh + markers
│   ├── player/player.tscn
│   ├── weapons/shotgun_viewmodel.tscn
│   ├── enemies/zombie.tscn
│   ├── animals/{animal.tscn, giraffe.tscn, elephant.tscn}
│   ├── world/{enclosure.tscn, feeder_giraffe.tscn, feeder_elephant.tscn,
│   │          food_crate_spawn.tscn, zombie_spawn.tscn}
│   ├── pickups/{food_crate.tscn, ammo_pickup.tscn}
│   ├── ui/{hud.tscn, objective_marker.tscn, end_screen.tscn, pause_menu.tscn}
│   └── tests/                   # one sandbox scene per system
├── scripts/
│   ├── autoload/{event_bus.gd, game_manager.gd}
│   ├── components/{health_component.gd, interactable.gd, hurtbox.gd, stamina.gd}
│   ├── data/                    # Resource classes (*_config.gd, wave_config.gd)
│   ├── player/{player_controller.gd, player_interactor.gd, player_carry.gd}
│   ├── weapons/{weapon_manager.gd, shotgun.gd, ammo_state.gd, axe.gd}
│   ├── enemies/{zombie.gd, zombie_target_selector.gd, zombie_spawner.gd}
│   ├── animals/{animal.gd, animal_needs.gd, animal_lure.gd}
│   ├── world/{enclosure.gd, enclosure_registry.gd, feeder.gd, food_crate_spawn.gd}
│   ├── pickups/{food_crate.gd, ammo_pickup.gd, ammo_spawn_point.gd, ammo_spawn_director.gd}
│   ├── systems/{wave_manager.gd, wave_schedule.gd, score_manager.gd}
│   └── ui/{hud.gd, objective_marker.gd, end_screen.gd, pause_menu.gd}
└── tests/                       # GUT unit tests
```

### 2.3 Autoloads

| Autoload | Responsabilidad |
|---|---|
| `EventBus` | Solo declara señales globales: `zombie_killed`, `coins_earned(amount)`, `animal_fed(animal_id)`, `animal_state_changed(animal_id, state)`, `animal_escaped(animal_id)`, `animal_recaptured(animal_id, enclosure)`, `animal_died(animal_id, position)`, `enclosure_damaged(enclosure)`, `enclosure_destroyed(enclosure)`, `player_died`, `player_respawned`, `wave_started(index)`, `wave_break_started(index)`, `game_won(stats)`, `game_lost(stats)`, `ammo_changed(mag, reserve)`, `ammo_collected(amount)`, `score_changed(coins)`, `zombie_count_changed(alive, pending)` |
| `GameManager` | Estado global de la partida (`PLAYING`, `PAUSED`, `WON`, `LOST`), tiempo, estadísticas, animales vivos (derrota cuando son 0) y reinicio |

`WaveManager`, `ScoreManager` y `EnclosureRegistry` son nodos dentro de `game.tscn`. Su ciclo de vida queda atado a la partida y reiniciar es solo recargar la escena.

### 2.4 Componentes reutilizables

| Componente | Tipo base | Uso |
|---|---|---|
| `HealthComponent` | `Node` | Vida actual y máxima, `take_damage()`, `heal()`, señales `health_changed` y `died`. Lo usan el jugador, los zombis, los animales **y los recintos** (como integridad) |
| `Interactable` | `Area3D` | Zona de interacción con `prompt_text`, `can_interact(player)` e `interact(player)`. Lo usan la caja de alimento y el comedero |
| `Hurtbox` | `Area3D` | Recibe golpes y los pasa al `HealthComponent` |
| `Stamina` | `RefCounted` (lógica pura) | Gasto, recuperación y umbral de cansancio. Lo usan los animales escapados (y en el futuro, la carrera del jugador) |

### 2.5 Sistemas

| Sistema | Diseño |
|---|---|
| **Jugador** | `CharacterBody3D` + `Camera3D` + "ViewModel" (instancia de `brazo_escopeta.glb`). `PlayerInteractor` busca el `Interactable` más cercano frente a la cámara. `PlayerCarry` maneja `ARMED` y `CARRYING`: en `CARRYING` reproduce `P_Caja`, oculta la escopeta y bloquea el disparo |
| **Armas** | `WeaponManager` en el jugador: arma equipada (escopeta / hacha), cambio con animación y bloqueo en `CARRYING`. Recuerda el arma activa para restaurarla después de alimentar |
| **Hacha** | Golpe cuerpo a cuerpo con `ShapeCast3D` (o una consulta de esfera) frente a la cámara, filtrada por el ángulo del arco. Se ordena por distancia y se aplica a un máximo de N zombis. Cadencia con `Timer` y retroceso por impulso en el zombi. El viewmodel sujeta `hacha.glb` al hueso `RightHand_06` (escala 0.55, porque el rig está escalado ×3). La animación `E_Martillo` saca el brazo de la cámara, así que el golpe es **procedural**: el brazo gira alrededor de la cámara (preparación, corte diagonal y recuperación) con un Tween, igual que la recarga. El daño llega `hit_delay` segundos después de iniciar el golpe. `HealthComponent.find_for_hit()` es compartido con la escopeta y respeta `can_receive_damage_from()` |
| **Escopeta** | Hitscan con N rayos (`intersect_ray`) con dispersión. `AmmoState` (lógica pura) guarda cargador y reserva. Animaciones `D_Escopeta` (disparo), `E_Escopeta` (sacar) y `reload` (nueva). Retroceso de cámara con `Tween` |
| **Zombis** | `CharacterBody3D` + `NavigationAgent3D` con avoidance + `HealthComponent` (los golpes usan la cápsula del cuerpo; no hizo falta un `Hurtbox` aparte). El modelo va girado 180° porque mira a +Z. Estados `IDLE`, `CHASE`, `ATTACK`, `HIT` y `DEAD`. `ZombieTargetSelector` decide el objetivo según su rol: un **cazador** persigue al jugador; un **destructor** va al recinto ocupado más cercano y cambia al jugador si recibe daño o si el jugador se acerca. Cualquier zombi prioriza a un animal escapado si está dentro de su radio de detección |
| **Navegación** | `NavigationRegion3D` con navmesh horneado a partir de las colisiones del mapa. Las cercas de los recintos son obstáculos, y los zombis atacan la cerca desde el borde exterior |
| **Recintos** | `Enclosure` (`Node3D`) con: `HealthComponent` (integridad), un área interior (`Area3D`) que detecta la llegada del animal, el punto de anclaje del comedero, puntos de paseo y puntos de ataque exteriores para los zombis. `EnclosureRegistry` lleva la lista de recintos, su ocupante y si están intactos o destruidos, y responde "¿cuál es el refugio libre más cercano?" |
| **Animales** | `Animal` (`CharacterBody3D` + `NavigationAgent3D`) + `AnimalNeeds` (hambre: gracia, pérdida de vida y umbral de debilidad) + `Stamina` + `AnimalLure`. Estados: `CONTAINED_IDLE`, `CONTAINED_WALK`, `EATING`, `WEAK`, `FLEEING`, `TIRED`, `FOLLOWING`, `DEAD`. Al morir emite `animal_died(id, position)` |
| **Recaptura** | El `Animal` escapado revisa cada 0.25 s si el jugador carga comida dentro de `lure_radius` → `FOLLOWING` (lo deja más allá de `follow_max_radius`). `EnclosureRegistry` revisa los animales en `FOLLOWING`: si uno está a menos de `recapture_radius` de la cerca de un refugio libre e intacto → `assign(animal, refuge, near)` lo coloca adentro junto a ese punto, mueve su comedero al anclaje del refugio y emite `animal_recaptured`. Los estados del animal escapado son `ESCAPING` (sale recto por la cerca caída), `LOOSE`, `FLEEING`, `TIRED` (`Stamina`) y `FOLLOWING`; se mueve con un `NavigationAgent3D` creado en código. Los zombis eligen objetivo con `ZombieTargetSelector` (lógica sin nodo) y un destructor golpea desde el punto de ataque más cercano del recinto |
| **Muerte del jugador** | `game.gd` escucha `player_died`, espera `PlayerConfig.respawn_delay` (se pausa con el juego) y reaparece al jugador en `PlayerSpawn` con vida completa; la cámara cae al suelo mientras tanto. Los zombis pasan a `IDLE` mientras el jugador está muerto |
| **Zombis de prueba** | Hasta que exista `WaveManager` (Fase 8), `ZombieSpawner.test_zombie_count` crea zombis ya alertados en los puntos del perímetro al empezar la partida |
| **Zombificación** | `ZombieSpawner` escucha `animal_died` y genera la horda extra en esa posición, respetando el máximo de vivos. Los zombis que no caben se encolan |
| **Comederos** | Un `Feeder` por animal, con un `Interactable` que acepta la caja si el jugador está `CARRYING` y el animal está contenido. El de la jirafa es elevado y el del elefante es bajo |
| **Cajas** | Implementación actual: `FoodCrateDirector` llena cinco puntos fijos agrupados en Tienda (3) y Veterinaria (2), con máximo global de cinco y reposición serial cada 30 s. Mejora documentada: inspeccionar el modelo para mover o añadir puntos en las zonas tipo quiosco y agrupar allí las cajas en pequeños montones, manteniendo la distancia a recintos y aparición. Definir marcadores y cantidad por montón después de validar la geometría y accesibilidad del mapa. |
| **Munición** | `AmmoPickup` (`Area3D`) que se recoge al contacto. Hay dos fuentes: lo que sueltan los zombis (según su probabilidad) y `AmmoSpawnDirector`, que reparte cajas al azar entre los `Marker3D` de `Markers/AmmoSpawns` del nivel (sin clase propia, igual que los puntos de cajas de comida) (activas a la vez, reaparición y un punto distinto al anterior). Las cajas del mapa llevan una `OmniLight3D` con pulso (Tween de `light_energy`) y un material emisivo para que se distingan a distancia |
| **Sonidos y efectos** | `Sfx` (estático) crea reproductores de un solo uso en el bus `SFX` que se liberan al terminar. `HitEffects.spawn_impact()` dibuja la chispa de impacto de ambas armas. Los WAV provisionales se generan con `tools/generate_sfx.py` (síntesis propia) y se pueden reemplazar por grabaciones sin tocar código |
| **Oleadas** | `WaveManager` + `WaveSchedule` (lógica pura del cronograma: cuenta regresiva → oleada → descanso → … → terminado; devuelve cuántos zombis toca crear en cada paso). El `WaveManager` reparte destructores según la proporción de la oleada de forma determinista, publica `wave_started`, `wave_break_started` y `zombie_count_changed`, y llama a `GameManager.finish_victory()` al terminar la oleada 3 si queda un animal vivo. `WaveHud` muestra oleada, tiempo y contador. `ZombieSpawner` aplica el intervalo, el máximo de vivos, la proporción de destructores y los multiplicadores. Los zombis vivos persisten entre oleadas |
| **Monedas** | `ScoreManager` escucha `zombie_killed`, `coins_earned`, `animal_recaptured`, `player_died` y `animal_died`; suma/resta las cantidades configurables de `ScoreConfig`/`AnimalConfig`, nunca baja de 0 y emite `score_changed`. Se usa un único saldo de monedas, sin gasto en esta versión |
| **HUD** | `CanvasLayer` que solo escucha señales. `PlayerStatusHud` muestra vida, icono del arma y munición (colores de `PlayerStatusHudConfig`: reserva baja y cargador vacío), monedas, tiempo de supervivencia e indicador de carga. `AnimalHealthHud` muestra una tarjeta compacta por animal cercano, con una barra amarilla más pequeña de integridad del recinto justo arriba de la barra verde de vida animal, más el estado (`Animal.get_status_key()`); ambas barras leen sus `HealthComponent` y se actualizan de forma independiente; no se muestra saciedad. `ObjectiveMarkers` dibuja marcadores en pantalla (flecha en el borde si el objetivo queda fuera) hacia los animales escapados y los refugios libres, con `ObjectiveMarkerConfig`. `EndScreen` muestra victoria o derrota con las estadísticas de `GameManager`, pausa el juego y ofrece reiniciar o salir al menú; el menú de pausa ofrece continuar, controles, reiniciar y salir |
| **Mensajes de acción** | `ActionFeed` (`scenes/ui/action_feed.tscn`) en el HUD: solo escucha señales de `EventBus` (`food_crate_picked_up`, `food_crate_dropped`, `ammo_collected`, `ammo_reserve_full`, `weapon_empty`, `action_blocked`, `animal_fed`, `animal_weak_changed`, `animal_died`, `weapon_changed`, `player_died` y `player_respawned`) y las convierte en textos traducidos. `ActionFeedConfig` define duración, desvanecido, máximo visible, tiempo antes de repetir y colores por tipo. Los mensajes de un animal usan claves por especie (`MSG_FED_GIRAFFE`) para concordar el artículo en español |

En la Fase 4, `AnimalNeeds` mantiene el temporizador de hambre independiente de `HealthComponent`. Empieza lleno para dar el periodo de gracia configurable de 120 s. Alimentar cura solo si la vida está por debajo del máximo, pero siempre reinicia el temporizador. Al agotarse, `AnimalNeeds` aplica daño gradual. La fila próxima del HUD muestra solo vida y no dibuja saciedad.

La próxima ampliación del HUD añade a esa fila una barra amarilla más pequeña de integridad del recinto, justo arriba de la barra verde de vida del animal. Esta segunda lectura solo se vincula cuando el animal tiene un recinto asignado. La mejora de comida requiere primero identificar en el modelo los quioscos utilizables y validar que los puntos no queden demasiado cerca de recintos o de la aparición.

El comedero expone `State.EMPTY` al iniciar, `State.FULL` después de alimentarlo y vuelve a `EMPTY` al agotarse la saciedad. Sus señales son el contrato que consumirá la entrega visual de la spec 006; los modelos actuales aún contienen comida estática.

La escopeta consulta `Animal.can_receive_damage_from(source)` antes de aplicar daño. La configuración de la jirafa desactiva el daño del jugador. Al morir se emite `animal_died` antes de comenzar el retraso de desaparición; el evento conserva la posición para zombificación futura.

### 2.6 Input map

Acciones (en inglés) con teclado/mouse y gamepad: `move_forward`, `move_back`, `move_left`, `move_right`, `look_up`, `look_down`, `look_left`, `look_right`, `sprint`, `fire`, `reload`, `switch_weapon`, `weapon_1`, `weapon_2`, `interact` y `pause`. El HUD detecta el último dispositivo usado para mostrar el icono correcto.

---

## 3. Pipeline de assets

### 3.1 Flujo general

```
Descarga (assets/models/) ──► Blender (escala, animaciones faltantes, limpieza) ──► GLB ──► zoo-zombie-godot/assets/models/
Script procedural (blender_zoo-zombie/scripts/) ────────────────────────────────────────► GLB ──┘
```

Ver [ADR-0001](../decisions/0001-pipeline-de-assets.md).

### 3.2 Preparación de los modelos descargados

1. Importar el GLB en Blender, normalizar la escala a metros reales (jirafa ~5 m, elefante ~3.2 m, zombi ~1.8 m) y el origen a nivel del suelo.
2. Renombrar las acciones a nombres estándar en inglés: `idle`, `walk`, `run`, `eat`, `weak`, `death`, `attack`, `hit`, `fire`, `reload`, `draw` y `carry`.
3. Agregar las acciones faltantes (sección 1.4) por script.
4. Eliminar lo que no se usa (en los brazos, las animaciones de otras herramientas) para reducir el tamaño.
5. Exportar a `zoo-zombie-godot/assets/models/...`.

Todo esto lo hace un script por modelo: `blender_zoo-zombie/scripts/prepare/prepare_<model>.py`. Así es reproducible.

### 3.3 Importación y optimización del mapa

1. Con `export_map.py`, exportar las colecciones jugables a GLB, **excluyendo** `00_AUXILIAR_CAMARA_LUZ`, `06Z_RECINTOS_ANTERIORES_OCULTOS`, las curvas `GUIA_*` y las luces.
2. Convertir los textos (`FONT`) a malla.
3. **Vegetación:** el pasto se reemplaza por `MultiMeshInstance3D`. Los árboles y arbustos se instancian a partir de pocas mallas únicas.
4. **Colisiones:** con los sufijos de importación de Godot (`-col`, `-colonly`, `-convcolonly`) en mallas simplificadas. El pasto no lleva colisión.
5. Hornear el navmesh en `zoo_level.tscn`.
6. **Coordenadas:** Blender (x, y, z) → Godot (x, z, −y). El exportador glTF lo hace automáticamente.

**Resultado de la Fase 1 (2026-11-17):**

- `export_map.py` exporta el mapa a `assets/models/map/zoo_map.glb` (19.6 MB). Además de lo descrito arriba, **reemplaza los colores procedurales** (ruido + rampa de color, que glTF no puede exportar) por el color de viewport de cada material (22 materiales), y **reduce los árboles** sin romper sus mallas compartidas. Así el mapa baja de ~1.01 M a ~606 000 triángulos.
- Las colisiones y la vegetación se resuelven **en Godot** con `scripts/import/zoo_map_post_import.gd`, no con sufijos en Blender, para no modificar el `.blend`. Hay 163 colisionadores (trimesh para terreno, estructuras, recintos y cercas; convexos para detalles; cilindros para troncos), y **757 plantas se convierten en 24 `MultiMeshInstance3D`**.
- Navmesh horneado con `tools/bake_navmesh.gd`: 2 542 polígonos, agente de radio 0.5 m. El área caminable sigue la cerca perimetral irregular del zoológico.
- `tools/validate_level.gd` comprueba que cada marcador esté sobre el suelo, libre de colisiones y sobre el navmesh. Los puntos de aparición de zombis se recolocaron junto al borde interior de la cerca. El punto "SouthEast" se descartó porque quedaba a 20 m de la jirafa. Quedan 8 puntos, todos a 36 m o más de los recintos.
- **Rendimiento** (`-- --perf`, 1920×1080, Apple M3): 120 FPS de promedio, mínimo 113, ~1 060 draw calls. El límite lo pone la frecuencia de la pantalla. CA-15 se cumple.

**Resultado de la Fase 2 (2026-11-17):**

| GLB en Godot | Script | Resultado |
|---|---|---|
| `animals/giraffe.glb` | `prepare/prepare_giraffe.py` | 5.0 m, 7 animaciones (`idle`, `walk`, `run`, `eat`, `attack`, `weak`, `death`), 9.7 MB |
| `animals/elephant.glb` | `prepare/prepare_elephant.py` | 3.2 m, las mismas 7 animaciones, 8.2 MB |
| `zombies/zombie.glb` | `prepare/prepare_zombie.py` | 1.8 m, 9 animaciones (`idle`, `idle_2`, `walk`, `walk_2`, `run`, `attack`, `attack_2`, `hit`, `death`), 1.2 MB |
| `weapons/fp_arms_shotgun.glb` | `prepare/prepare_fp_arms.py` | Brazo derecho + escopeta, ~0.9 m, centrado en el origen; `shotgun_idle`, `shotgun_fire`, `shotgun_draw`, `axe_idle`, `axe_swing` |
| `weapons/axe.glb` | `prepare/prepare_axe.py` | 0.75 m, mango vertical, origen en el punto de agarre |
| `props/*.glb` | `models/*.py` | Caja de comida, caja de munición y comederos, todos procedurales y de menos de 700 triángulos |

Lecciones del pipeline (ya resueltas en `lib/`):

- El importador glTF de Blender debe usar `guess_original_bind_pose=False`. Si no, los esqueletos convertidos desde FBX (Sketchfab) se exportan con las animaciones giradas 90° (el modelo queda acostado).
- Los modelos de Sketchfab vienen envueltos en cadenas de nodos vacíos con escalas que se compensan (×34 y ×0.01). Se eliminan solo los vacíos **por encima** del esqueleto. Los de abajo se conservan porque pueden ser piezas unidas a huesos o animadas, como la escopeta y su corredera.
- La verificación visual se hace **en Godot** con `tools/preview_model.gd`, porque el ida y vuelta por Blender no es confiable para revisar esqueletos.

**Resultado de la Fase 3 (2026-11-17):**

- **Recintos:** `Enclosure` se construye en tiempo de ejecución a partir de la malla del mapa. Su contorno es la **envolvente convexa** de esa malla vista desde arriba, reducida 1.2 m, y coincide con la cerca en hexágonos y rectángulos. El suelo se mide con rayos verticales, porque la malla llega bajo tierra. Los puntos para deambular deben estar dentro del contorno, libres de obstáculos, a nivel del suelo (sin rocas ni vigas) y con línea libre desde el animal.
- **Comederos:** se ubican con marcadores en el nivel (`Markers/Enclosures/<recinto>/FeederAnchor`), dentro de la cerca del lado del camino. El área de interacción, de 3.2 m, atraviesa la cerca para que el jugador alimente desde afuera.
- **Interacción por proximidad** (`PlayerInteractor`), no por rayo: las cercas son mallas con colisión y bloquearían un rayo. Entre varios candidatos se elige el que la cámara mira.
- **Viewmodel:** el GLB de brazos se importa en Godot a ~1/3 de su tamaño, por la escala negativa del esqueleto original. Se compensa en `player.tscn` con escala ×3 y una orientación calibrada con capturas. Las mallas del viewmodel no proyectan sombra.
- Prueba de integración en `tests/integration/test_feeding_flow.gd` (recoger → cargar → alimentar).

### 3.4 Scripts de Blender

```
blender_zoo-zombie/
├── mapacompleto_2_sin_entorno.blend
└── scripts/
    ├── lib/{materials.py, mesh_utils.py, anim_utils.py, export_utils.py}
    ├── prepare/                # downloaded models → game-ready GLB
    │   ├── prepare_giraffe.py  # scale, rename actions, add weak/death
    │   ├── prepare_elephant.py
    │   ├── prepare_zombie.py
    │   └── prepare_fp_arms.py  # strip unused tools, add reload
    ├── models/                 # procedural, one script per model
    │   ├── food_crate.py
    │   ├── ammo_box.py
    │   ├── giraffe_feeder.py
    │   └── elephant_feeder.py
    └── export/export_map.py
```

**Cómo se ejecutan:**

- **Desde Blender:** pestaña *Scripting* → abrir el script → *Run Script*.
- **Sin interfaz:**
  ```bash
  "<ruta a Blender>" -b --python blender_zoo-zombie/scripts/models/food_crate.py -- --output godot_zoo-zombie/zoo-zombie-godot/assets/models/props/food_crate.glb
  ```
- **Por MCP:** el agente ejecuta el script en el Blender abierto y revisa el resultado con capturas.

---

## 4. Fases de implementación

> Ajustes respecto a la propuesta original:
> - La **Fase 1** incluye la **base técnica**: jugador en primera persona y mapa importado. Sin eso no se puede probar ninguna fase siguiente.
> - La **Fase 2** pasa a ser "preparar los modelos descargados", porque ya existen modelos animados y no hace falta modelar desde cero.
> - Se agrega una **fase nueva (7)** para recintos destructibles, escape y recaptura. Depende de que los zombis ya existan. Por eso hay 10 fases.

| Fase | Contenido | Entregable verificable | Depende de |
|---|---|---|---|
| **1** | Análisis ✅ + base técnica: carpetas, input map, `EventBus`, `GameManager`, clases de datos, mapa con colisiones y navmesh, jugador en primera persona | Caminar por el zoológico en primera persona a 60 FPS | — |
| **2** | Modelos: preparar jirafa, elefante, zombi y brazos; animaciones faltantes; comederos, cajas y munición procedurales | Todos los GLB en Godot con sus animaciones | 1 |
| **3** | Cajas de alimento, transporte (`ARMED`/`CARRYING`), comederos e interacción | Recoger una caja y alimentar a un animal; no se puede disparar mientras se carga | 1, 2 |
| **4** | Hambre, debilidad y muerte de los animales; derrota si mueren ambos | Los animales se debilitan y mueren si no se les alimenta | 3 |
| **5** | Escopeta, hacha, cambio de arma, munición soltada y munición repartida en el mapa | Disparar, golpear, cambiar de arma y encontrar munición | 1, 2 |
| **6** | IA de zombis (cazadores): navegación, persecución, ataque y muerte; muerte y reaparición del jugador | Los zombis persiguen y atacan, y mueren con la escopeta | 5 |
| **7** | Recintos destructibles, zombis destructores, escape (huida y resistencia), atracción con comida, refugios y zombificación | Ciclo completo: recinto destruido → escape → recaptura | 4, 6 |
| **8** | Oleadas, temporizadores y aparición | 3 oleadas con descanso y dificultad creciente | 7 |
| **9** | HUD, marcadores, puntuación, pantallas de victoria y derrota, pausa | Partida completa de inicio a fin | 3–8 |
| **10** | Integración, balance, pruebas y optimización | Cumple todos los CA de la spec | 1–9 |

La Fase 5 puede avanzar en paralelo con la 3 y la 4.

## 5. Estrategia de pruebas

- **Pruebas unitarias (GUT):** cubren la lógica pura: `HealthComponent`, `AnimalNeeds`, `Stamina`, `AmmoState`, `WaveSchedule`, `ScoreManager` y la elección de refugio de `EnclosureRegistry`. Se ejecutan en modo headless.
- **Escenas de prueba** (`scenes/tests/`): una por sistema. Por ejemplo, un zombi contra un recinto, o un animal escapado con zombis cerca.
- **Pruebas manuales por fase:** checklist con los criterios de aceptación de la spec.
- **Rendimiento:** monitor de Godot en el mapa completo con 16 zombis.

## 6. Riesgos

La reparación de recintos se reserva para una funcionalidad futura. Antes de implementarla se definirá en una spec si se reparan recintos dañados, destruidos o ambos, y qué costo, materiales y tiempo requiere.

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Mapa de ~1 M de triángulos | FPS bajos | MultiMesh y reducción de la vegetación |
| Los modelos animados vienen de distintos autores | Estilos visuales distintos | Ajustar los materiales a la paleta común; aceptar diferencias menores |
| Jirafa (9.9 MB) y elefante (8.3 MB) con texturas pesadas | Tamaño y memoria | Reducir texturas a 1024 px al prepararlos |
| Animaciones de muerte y recarga hechas por código se ven rígidas | Calidad visual | Usar poses clave simples con buena curva (ease). Iterar con capturas por MCP |
| Navmesh en un mapa grande, y zombis que atacan cercas | Zombis atorados | Puntos de ataque explícitos fuera de cada recinto y escena de prueba |
| Animales que deambulan en línea recta y rozan rocas (Fase 3) | Visual: se detienen y cambian de rumbo | Hoy: barrido con el ancho del cuerpo y nuevo destino al atorarse. Mejora pendiente T-079: rutas con navmesh por recinto y evasión de obstáculos |
| Animal escapado atorado en la geometría | Recaptura imposible | El animal usa el navmesh. Si queda atorado, se teletransporta al punto navegable más cercano |
| Compatibilidad de GUT con Godot 4.7 | Sin tests automáticos | Comprobarlo en la Fase 1. La alternativa es gdUnit4 |

## 7. Decisiones técnicas

| ID | Decisión | Registro |
|---|---|---|
| ADR-0001 | Pipeline de assets: GLB, descargas en `assets/`, modelos listos para el juego dentro del proyecto Godot | [`0001-pipeline-de-assets.md`](../decisions/0001-pipeline-de-assets.md) |
| — | Primera persona, PC con teclado/mouse y gamepad | Spec D-01, D-03 |
| — | Elefante en lugar de hipopótamo (hay modelo animado) | Spec D-05 |
| — | Disparo hitscan (raycast) | Este plan, 2.5 |
| — | Jolt Physics (ya configurado) | `project.godot` |
