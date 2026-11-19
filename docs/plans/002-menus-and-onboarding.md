# Plan técnico 002: Menús, configuración e instrucciones

**Estado:** Borrador, pendiente de aprobación · **Versión:** 0.3 · **Fecha:** 2026-11-18
**Spec:** [`specs/002-menus-and-onboarding.md`](../specs/002-menus-and-onboarding.md) · **Tareas:** [`tasks/002-menus-and-onboarding.md`](../tasks/002-menus-and-onboarding.md)
**Se apoya en:** [`plans/001-zoo-survival.md`](001-zoo-survival.md): `EventBus`, `GameManager`, input map y HUD.

---

## 1. Relación con la spec 001

| Elemento de la 001 | Qué hace la 002 |
|---|---|
| RF-102: iconos según el dispositivo | Se implementa como autoload compartido `InputGlyphs` (aquí), que también usan el HUD y los consejos |
| RF-103: avisos de oleada | Se detallan formato y contenido (RF-40 a RF-43 de la 002) |
| RF-107: pausa y pantallas finales | El menú de pausa se amplía (RF-80 a RF-83 de la 002). Las pantallas de victoria y derrota siguen en la 001 |
| Input map (plan 001 §2.6) | Se agregan las acciones de menú; la pantalla de controles solo consulta las asignaciones actuales |

No se duplica nada: el HUD de la 001 y las pantallas de la 002 consumen los mismos autoloads.

## 2. Arquitectura

### 2.1 Autoloads nuevos

| Autoload | Responsabilidad |
|---|---|
| `SettingsManager` | Carga y guarda `user://settings.cfg` (`ConfigFile`). Aplica gráficos (`DisplayServer`, `Viewport`, `RenderingServer`), audio (`AudioServer`, buses `Master`, `Music`, `SFX`, `UI`), controles (sensibilidad, invertir Y, FOV) e idioma (`TranslationServer`). Emite `setting_changed(section, key, value)` |
| `InputGlyphs` | Detecta el último dispositivo usado (teclado/mouse, Xbox o PlayStation, por `Input.get_joy_name`). Devuelve la textura del icono de una acción. Emite `device_changed` |
| `TutorialManager` | Escucha al `EventBus` y a los sistemas de la 001. Decide qué consejo (TIP-xx) mostrar, maneja la cola con prioridad y guarda los vistos en `user://profile.cfg` |
| `SceneLoader` | Cambia de escena con pantalla de carga y carga en segundo plano (`ResourceLoader.load_threaded_request` + `load_threaded_get_status` para el progreso) |

`SettingsManager` debe cargarse **antes** que el resto, para que la ventana y el audio arranquen con la configuración guardada.

### 2.2 Escenas y scripts

La primera entrega incorpora un menú inicial mínimo (jugar, controles y salir) y un menú de pausa (continuar y controles) para dar acceso a la tabla de controles. Esto cubre el acceso pedido, pero no completa RF-01 a RF-04 del menú principal ni el resto de la Fase B (título, carga y confirmaciones).

```
scenes/ui/
├── theme/ui_theme.tres            # shared Theme (fonts, colors, focus styles)
├── menus/
│   ├── title_screen.tscn
│   ├── main_menu.tscn
│   ├── how_to_play.tscn           # tabbed pages
│   ├── controls_menu.tscn         # read-only keyboard/gamepad bindings table
│   ├── settings_menu.tscn         # tabs: Graphics, Audio, Controls, Gameplay
│   ├── credits.tscn
│   ├── confirm_dialog.tscn        # reusable yes/no (+ timeout for display changes)
│   └── pause_menu.tscn
├── loading_screen.tscn
├── briefing.tscn
├── tip_popup.tscn                 # contextual tip widget (in HUD layer)
├── wave_announcer.tscn            # wave / break / final wave banners
└── widgets/{input_glyph.tscn, setting_slider.tscn, setting_option.tscn}

scripts/
├── autoload/{settings_manager.gd, input_glyphs.gd,
│             tutorial_manager.gd, scene_loader.gd}
├── data/{tip_data.gd, tip_catalog.gd, how_to_play_page.gd}
└── ui/menus/*.gd, ui/{briefing.gd, tip_popup.gd, wave_announcer.gd, loading_screen.gd}

config/
├── tips/tip_catalog.tres          # TIP-01..13: id, trigger, text key, priority, duration
├── how_to_play/*.tres             # one page per section (title key, bullet keys, image)
└── ui_config.tres                 # countdown, tip duration, banner duration, confirm timeout

assets/ui/
├── fonts/
├── glyphs/{keyboard,xbox,playstation}/   # input icons (e.g. Kenney Input Prompts, CC0)
└── how_to_play/                          # screenshots/illustrations

localization/
└── strings.csv                    # keys + es (default) + en → imported as .translation
```

### 2.3 Datos de los consejos

`TipData` (Resource): `id`, `trigger` (enum), `text_key` (clave de traducción con marcadores `{animal}` y `[action:interact]`), `priority` (`NORMAL` o `HIGH`) y `duration`.

`TutorialManager` conecta cada `trigger` a la señal correspondiente:

| Trigger | Fuente |
|---|---|
| `GAME_STARTED` | `briefing.closed` |
| `NEAR_FOOD_CRATE` | `PlayerInteractor.focus_changed` (un `Interactable` de tipo caja) |
| `CARRY_STARTED` | `PlayerCarry.state_changed` |
| `ANIMAL_HUNGRY` | `AnimalNeeds.satiety_changed` < 0.5 |
| `ZOMBIE_SEEN` | `ZombieSpawner` / prueba de visibilidad en pantalla |
| `OUT_OF_AMMO` | `EventBus.ammo_changed(0, 0)` |
| `AMMO_CRATE_SEEN` | `AmmoSpawnDirector` + prueba de visibilidad |
| `ENCLOSURE_ATTACKED` | `EventBus.enclosure_damaged` |
| `ANIMAL_ESCAPED` | `EventBus.animal_escaped` |
| `ANIMAL_FOLLOWING` | `EventBus.animal_state_changed(_, FOLLOWING)` |
| `PLAYER_DIED` | `EventBus.player_died` |
| `WAVE_BREAK` | `EventBus.wave_break_started` |
| `ANIMAL_DIED` | `EventBus.animal_died` |

Los marcadores `[action:x]` se sustituyen por el icono de `InputGlyphs` (`RichTextLabel` con `[img]`).

### 2.4 Pausa

`get_tree().paused = true`. Los nodos de interfaz de pausa, consejos y diálogos usan `process_mode = PROCESS_MODE_ALWAYS`. Los sistemas de la 001 (`AnimalNeeds`, `WaveManager`) usan `PROCESS_MODE_PAUSABLE`, así que se detienen solos (CA-07). La desconexión del control se detecta con `Input.joy_connection_changed`.

### 2.5 Navegación con gamepad

- Cada pantalla define el primer control con foco (`grab_focus()` en `_ready` y al volver de una subpantalla).
- Las acciones `ui_accept`, `ui_cancel`, `ui_left/right/up/down` y las nuevas `ui_tab_prev` y `ui_tab_next` se asignan a teclado y gamepad.
- El tema define un estilo de foco muy visible.

## 3. Decisiones técnicas

| Decisión | Motivo |
|---|---|
| `ConfigFile` en `user://` para las opciones y el perfil; los controles son de solo consulta | Es nativo, legible y no requiere dependencias |
| Iconos de controles de **Kenney Input Prompts** (CC0) | Cubre teclado, Xbox y PlayStation con estilo uniforme y licencia libre |
| Textos con `TranslationServer` + CSV, español por defecto | Lo decidió el usuario (spec D-01): el español es el idioma principal y el inglés es opcional. Las claves de traducción van en inglés |
| Consejos como datos (`.tres`) | Se agregan o cambian consejos sin programar (principio III de la constitución) |

## 4. Fases de implementación

Se integran con las fases de la 001:

| Fase | Contenido | Cuándo |
|---|---|---|
| **A** | Base: tema de interfaz, `SettingsManager`, `InputGlyphs`, `SceneLoader`, CSV de traducciones | En paralelo con la Fase 1 de la 001. Así la 001 ya usa la sensibilidad y los iconos |
| **B** | Título, menú principal, pausa, diálogo de confirmación y pantalla de carga | Después de la Fase 1 de la 001 |
| **C** | Configuración completa + pantalla informativa de controles (sin reasignación) | Después de B |
| **D** | Briefing, anunciador de oleadas, `TutorialManager` y consejos | Después de la Fase 8 (oleadas) de la 001 |
| **E** | How to Play (con capturas reales del juego) y créditos | Después de la Fase 9 de la 001 (el HUD ya existe para capturarlo) |
| **F** | Verificación completa con gamepad y resoluciones | Junto con la Fase 10 de la 001 |

## 5. Pruebas

- **Unitarias (GUT):** guardar y cargar en `SettingsManager`; cola y prioridad de `TutorialManager`, y que cada consejo se muestre una sola vez.
- **Manuales:** recorrido completo solo con el gamepad (CA-01), cambio de resolución con reversión, y lectura a 720p y 4K.
