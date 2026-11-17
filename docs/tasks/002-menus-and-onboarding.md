# Tareas 002: Menús, configuración e instrucciones

**Spec:** [`specs/002-menus-and-onboarding.md`](../specs/002-menus-and-onboarding.md) · **Plan:** [`plans/002-menus-and-onboarding.md`](../plans/002-menus-and-onboarding.md)

Convenciones: `[ ]` pendiente · `[x]` hecha · `[P]` paralelizable. **Ninguna fase empieza sin aprobación del usuario.**

---

## Fase A: Base de interfaz (en paralelo con la Fase 1 de la 001)

- [x] T-A01 [P] Crear el tema `ui_theme.tres`: tipografía, paleta y estilos de foco visibles — RF-101
- [x] T-A02 [P] Crear el autoload `SettingsManager` (cargar, guardar y aplicar), con buses de audio `Master`, `Music`, `SFX` y `UI`, y pruebas — RF-70 a RF-75
- [x] T-A03 [P] Crear el autoload `InputGlyphs`: detección de dispositivo y textura por acción; importar Kenney Input Prompts — RF-64
- [x] T-A04 [P] Crear el autoload `SceneLoader` con carga en segundo plano — RF-11
- [x] T-A05 Crear `localization/strings.csv` (es por defecto + en), importarlo en Godot y definir el español como idioma inicial — RF-102
- [x] T-A06 Agregar las acciones de menú (`ui_tab_prev` y `ui_tab_next`) al input map — RF-100

## Fase B: Menús principales

- [ ] T-B01 Crear `title_screen.tscn` con fondo de recorrido de cámara por el mapa — RF-01
- [ ] T-B02 Crear `main_menu.tscn` con las 6 opciones y navegación por teclado y gamepad — RF-02, RF-04, RF-100
- [ ] T-B03 Crear `confirm_dialog.tscn` reutilizable (con reversión por tiempo opcional) — RF-04, RF-74
- [ ] T-B04 Crear `loading_screen.tscn` con barra de progreso y consejo aleatorio — RF-10
- [ ] T-B05 Crear `pause_menu.tscn`: opciones, resumen del estado, pausa con detección de desconexión del control — RF-80 a RF-83
- [ ] T-B06 Definir el título como escena principal y conectar el flujo título → menú → carga → partida — §3 de la spec
- [ ] T-B07 Verificar — CA-01 (parcial), CA-07

## Fase C: Configuración y controles

- [ ] T-C01 Crear `settings_menu.tscn` con pestañas Graphics, Audio, Controls y Gameplay, y widgets reutilizables — RF-70 a RF-73
- [ ] T-C02 Confirmación con reversión a los 10 s para los cambios de pantalla — RF-74
- [ ] T-C03 Botón "Restaurar valores por defecto" por pestaña — RF-75
- [ ] T-C04 Crear el autoload `InputRemapper`: reasignar, detectar conflictos, intercambiar, restaurar y persistir, con pruebas — RF-61 a RF-63
- [ ] T-C05 Crear `controls_menu.tscn`: tabla teclado/gamepad con iconos y botones de reasignación — RF-60
- [ ] T-C06 Aplicar sensibilidad, invertir Y, FOV, vibración e intensidad del retroceso en el jugador de la 001 — RF-72, RF-73
- [ ] T-C07 Verificar — CA-05, CA-06

## Fase D: Instrucciones dentro del juego (después de la Fase 8 de la 001)

- [ ] T-D01 Crear `briefing.tscn`: 4 puntos con iconos, regla clave y cuenta regresiva para la oleada 1 — RF-20 a RF-23
- [ ] T-D02 Crear `wave_announcer.tscn`: oleada N/3, descanso con cuenta regresiva y consejo, oleada final — RF-40 a RF-43
- [ ] T-D03 Crear `TipData` + `tip_catalog.tres` con TIP-01 a TIP-13 — §6.1 de la spec
- [ ] T-D04 Crear el autoload `TutorialManager`: conexión de los disparadores, cola con prioridad y persistencia de los consejos vistos, con pruebas — RF-30 a RF-33
- [ ] T-D05 Crear `tip_popup.tscn` con iconos de controles dentro del texto — RF-30, RF-64
- [ ] T-D06 Opciones "Mostrar consejos" y "Reiniciar consejos" en Configuración — RF-34
- [ ] T-D07 Pregunta "¿Ver el tutorial rápido?" al elegir Jugar — RF-03
- [ ] T-D08 Verificar — CA-02, CA-03, CA-04

## Fase E: Cómo jugar y créditos (después de la Fase 9 de la 001)

- [ ] T-E01 Crear `HowToPlayPage` (Resource) y las 7 páginas de contenido — RF-50, RF-51
- [ ] T-E02 Hacer las capturas reales del juego y el HUD anotado — RF-51
- [ ] T-E03 Crear `how_to_play.tscn` con pestañas, accesible desde el menú principal y la pausa — RF-50, RF-52
- [ ] T-E04 Crear `credits.tscn` a partir del registro de `docs/assets.md` — RF-90
- [ ] T-E05 Escribir todos los textos en el CSV en español y su traducción al inglés — RF-102
- [ ] T-E06 Verificar — CA-08, CA-09

## Fase F: Verificación final (junto con la Fase 10 de la 001)

- [ ] T-F01 Recorrido completo solo con el gamepad — CA-01
- [ ] T-F02 Revisar la interfaz a 1280×720, 1920×1080, 2560×1600 y 4K — CA-10, RF-103
- [ ] T-F03 Revisar todos los criterios CA-01 a CA-10
