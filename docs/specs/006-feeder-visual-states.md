# Spec 006: Estados visuales de los comederos

**Estado:** Aprobada para entrega de arte por solicitud del usuario · **Versión:** 0.1 · **Fecha:** 2026-11-19
**Plan:** [`plans/006-feeder-visual-states.md`](../plans/006-feeder-visual-states.md) · **Tareas:** [`tasks/006-feeder-visual-states.md`](../tasks/006-feeder-visual-states.md)
**Depende de:** [`specs/001-zoo-survival.md`](001-zoo-survival.md) (RF-21 a RF-25 y RF-28) y su contrato `Feeder.State`.

---

## 1. Objetivo

Preparar modelos de comedero que muestren claramente si tienen comida. Los modelos actuales parecen llenos incluso al comenzar la partida; el estado visual inicial debe ser **vacío**. Al alimentar, se muestra **lleno**; cuando se agota la saciedad del animal, vuelve a **vacío**.

Esta entrega corresponde al colaborador de arte/modelos. El comportamiento del juego ya publica el estado lógico del comedero mediante `Feeder.state_changed`; esta spec no duplica la lógica de salud ni hambre.

## 2. Requisitos funcionales

| ID | Requisito |
|---|---|
| RF-01 | Cada modelo de comedero (jirafa y elefante) debe presentar dos estados claramente distinguibles: vacío y lleno. |
| RF-02 | El estado vacío no muestra heno, fruta u otro alimento dentro del comedero. El espacio interior debe leerse claramente como vacío desde la distancia normal de juego. |
| RF-03 | El estado lleno conserva los alimentos apropiados al animal y la forma actual del comedero. |
| RF-04 | Los estados deben poder activarse desde Godot sin sustituir la escena del `Feeder`, su colisión ni su interacción. Nodos de contenido con nombres estables `ContentsEmpty` y `ContentsFull` permiten al adaptador activar uno y ocultar el otro. |
| RF-05 | El recurso se genera y exporta mediante los scripts de Blender existentes. No se reemplazan los archivos fuente `.blend` del usuario. |
| RF-06 | La entrega conserva escala, orientación, materiales, licencia y convenciones del asset actual. No se incorporan recursos externos nuevos. |

## 3. Criterios de aceptación

- **CA-01:** En partida recién iniciada se ve el comedero de jirafa vacío, sin heno en la rejilla.
- **CA-02:** En partida recién iniciada se ve el comedero del elefante vacío, sin heno ni fruta en el recipiente.
- **CA-03:** Al cambiar `Feeder.state` a `FULL`, se muestra el contenido correspondiente; al volver a `EMPTY`, desaparece todo el contenido.
- **CA-04:** La forma, escala, orientación y colisiones del comedero se mantienen.
- **CA-05:** Los GLB se regeneran de forma reproducible desde `blender_zoo-zombie/scripts/models/`.

## 4. Fuera de alcance

- Cambiar cuánto curan los alimentos o cuánto dura la saciedad.
- Cambiar el HUD, la barra de vida o la lógica de `AnimalNeeds`.
- Crear animaciones, sonidos o partículas de comida.
- Cambiar el mapa, las ubicaciones o la interacción de los comederos.

## 5. Supuestos

| ID | Tema | Supuesto |
|---|---|---|
| S-01 | Identificadores de nodos | El adaptador Godot buscará `ContentsEmpty` y `ContentsFull` bajo `Model`. |
| S-02 | Estado lleno | Se reutilizan los alimentos low-poly actuales; no se incorporan nuevos assets. |
| S-03 | Estado inicial | Ambos comederos arrancan vacíos y pasan a llenos únicamente después de alimentar. |
