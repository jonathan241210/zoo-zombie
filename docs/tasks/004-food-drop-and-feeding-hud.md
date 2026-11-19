# Tareas 004: Soltar comida y HUD de alimentación

**Spec:** [`specs/004-food-drop-and-feeding-hud.md`](../specs/004-food-drop-and-feeding-hud.md) · **Plan:** [`plans/004-food-drop-and-feeding-hud.md`](../plans/004-food-drop-and-feeding-hud.md)

Convenciones:

- `[ ]` pendiente · `[x]` hecha
- `[P]`: puede hacerse en paralelo con otras tareas `[P]` de la misma fase.
- Cada tarea indica los requisitos que cubre (`RF-xx`) o el criterio de aceptación con que se verifica (`CA-xx`).
- **Ninguna fase empieza sin aprobación del usuario.**
- Las Fases C a F dependen de la **Fase 4 de la spec 001** (`AnimalNeeds`, T-040 a T-042) y, la F, del HUD (T-091 y T-092).

---

## Fase A: Soltar la caja (independiente)

- [x] T-D01 Agregar `PlayerCarry.drop()` y la señal `crate_dropped` — RF-01, RF-02
- [x] T-D02 Dar a `FoodCrate` el modo `is_dropped` (se recoge igual, sin reaparición) — RF-03
- [x] T-D03 Colocar la caja soltada con rayos hacia adelante y hacia el suelo, sin atravesar paredes — RF-06
- [x] T-D04 Respaldo de E en `PlayerInteractor`: si nada se puede activar y se carga una caja, soltarla; alimentar tiene prioridad — RF-01, RF-05
- [x] T-D05 `FoodCrateDirector`: contar las cajas sueltas en `active_count()` y no programar reaparición al recogerlas — RF-04
- [ ] T-D06 Pruebas GUT: `drop()`, conteo del director y ausencia de reaparición; ampliar `test_feeding_flow.gd` (recoger, soltar, recoger, alimentar) — CA-01, CA-02, CA-03
- [ ] T-D07 Verificar: soltar lejos y junto a un comedero, y contra una pared — CA-01, CA-02, CA-03

## Fase B: Animación, avisos y controles

- [ ] T-D08 Animación breve de soltar (`drop_time`) en `ViewModel`, con bloqueo del disparo durante ese tiempo — RF-07
- [ ] T-D09 Sonido de soltar y registro en `docs/assets.md` si es externo — RF-07
- [x] T-D10 [P] Aviso "Soltar (E)" en `InteractionPrompt` con el icono del dispositivo — RF-08
- [ ] T-D11 [P] Cambiar la fila de controles a "Interactuar (recoger, alimentar, soltar)" y agregar las claves de traducción — RF-41
- [ ] T-D12 [P] Consejo TIP-14 y texto en Cómo jugar > Animales y comida — RF-42, RF-43
- [ ] T-D13 Verificar con gamepad — CA-10, CA-11 (parcial)

## Fase C: Saturación (depende de T-040 a T-042 de la 001)

- [ ] T-D14 Crear `FeedingHudConfig` y `config/feeding_hud_config.tres` con colores, umbrales y distancias — CA-09
- [ ] T-D15 `AnimalNeeds`: exponer `satiety_remaining`, `satiety_ratio()` y la señal `satiety_changed(ratio, seconds_left)` — RF-13, RF-20, RF-21
- [ ] T-D16 Reiniciar la saturación al alimentar, y mantenerla corriendo escapado o con el jugador muerto — RF-22, RF-23
- [ ] T-D17 Pruebas GUT de la saturación: baja, se reinicia, llega a 0 y se detiene en pausa — CA-06
- [ ] T-D18 Verificar la duración configurable en el `.tres` de cada animal — CA-06, CA-09

## Fase D: Contador en el comedero

- [ ] T-D19 Crear `FeederTimer` (`Label3D` con billboard y sin prueba de profundidad) como hijo de `Feeder` — RF-30, RF-31
- [ ] T-D20 Conectarlo a `satiety_changed`: texto `27 s`, rojo y parpadeo bajo 10 s, `0 s` en rojo al agotarse — RF-32, RF-33
- [ ] T-D21 Reiniciarlo al alimentar y ocultarlo si el animal escapa o muere, mostrándolo de nuevo en el nuevo comedero — RF-34 a RF-36
- [ ] T-D22 Claves de traducción del contador (`FEEDER_SECONDS`) — RF-37
- [ ] T-D23 Verificar — CA-07, CA-08

## Fase E: Barras flotantes sobre el animal

- [ ] T-D24 Crear el shader `bar.gdshader` (ratio, color y fondo, con billboard) — RF-11
- [ ] T-D25 Crear `animal_bars.tscn` con la barra de vida (verde, roja bajo el umbral de debilidad) y la de saturación (amarilla, parpadea a 0) — RF-11 a RF-13
- [ ] T-D26 Mostrarlas solo a menos de 25 m de la cámara y ocultarlas si el animal muere — RF-14
- [ ] T-D27 Agregar los iconos (corazón y hoja) para no depender solo del color — RF-15
- [ ] T-D28 Verificar a 5, 15 y 30 m y con el máximo de zombis (FPS) — CA-05 (parcial)

## Fase F: Tarjeta del HUD (depende de T-091 y T-092 de la 001)

- [ ] T-D29 Aplicar los colores de `FeedingHudConfig` a las barras de la tarjeta (vida verde, saturación amarilla) con lectura numérica — RF-10, RF-15
- [ ] T-D30 Verificar — CA-05

## Fase G: Verificación final

- [ ] T-D31 Jugar con teclado y mouse y con gamepad: soltar, alimentar, ver barras y contador — CA-04, CA-11
- [ ] T-D32 Comprobar que cambiar la duración y los colores en los `.tres` se refleja sin tocar el código — CA-09
- [ ] T-D33 Revisar todos los criterios de aceptación CA-01 a CA-11

## Alcance adicional aprobado: indicadores básicos del jugador

- [x] T-D34 Mostrar vida actual/máxima del jugador y cargador/reserva en `PlayerStatusHud`, escuchando salud y munición — RF-50
- [ ] T-D35 Verificar visualmente la vida y la munición en juego — RF-50
