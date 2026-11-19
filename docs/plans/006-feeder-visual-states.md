# Plan técnico 006: Estados visuales de los comederos

**Estado:** Aprobado para entrega de arte · **Versión:** 0.1 · **Fecha:** 2026-11-19
**Spec:** [`specs/006-feeder-visual-states.md`](../specs/006-feeder-visual-states.md) · **Tareas:** [`tasks/006-feeder-visual-states.md`](../tasks/006-feeder-visual-states.md)

---

## 1. Alcance de la entrega

Trabajo para el colaborador de arte/modelos: actualizar los scripts procedurales de ambos comederos y exportar los GLB con una jerarquía que permita distinguir visualmente el contenido. La lógica de salud y saciedad vive en `AnimalNeeds`; no se vuelve a implementar aquí.

## 2. Contrato con el juego

La escena actual `Feeder` empieza en `State.EMPTY`, emite `state_changed(State.EMPTY/FULL)` y vuelve a `EMPTY` cuando la saciedad llega a cero. Bajo el nodo `Model`, cada GLB debe exponer:

```text
Model
├── FeederBase
├── ContentsEmpty
└── ContentsFull
```

`FeederBase` contiene la estructura compartida. `ContentsEmpty` contiene cualquier detalle que ayude a leer el recipiente vacío; `ContentsFull` agrupa todos los meshes de heno y fruta del estado lleno. El adaptador de Godot activa el grupo que corresponde y apaga el otro. La jerarquía no debe incluir colisiones ni el `Interactable`.

## 3. Fuentes y exportación

| Modelo | Script fuente | GLB de salida |
|---|---|---|
| Comedero elevado de jirafa | `blender_zoo-zombie/scripts/models/giraffe_feeder.py` | `godot_zoo-zombie/zoo-zombie-godot/assets/models/props/giraffe_feeder.glb` |
| Comedero bajo de elefante | `blender_zoo-zombie/scripts/models/elephant_feeder.py` | `godot_zoo-zombie/zoo-zombie-godot/assets/models/props/elephant_feeder.glb` |

Se respeta la regla de un script procedural por modelo. Se conservan materiales y geometría existentes; el estado vacío omite solamente los meshes que representan comida.

## 4. Revisión

El colaborador entrega los dos scripts actualizados, los dos GLB exportados y una captura de cada estado en Godot. El integrador conecta `state_changed` con la visibilidad de `ContentsEmpty` y `ContentsFull` y verifica CA-01 a CA-04.
