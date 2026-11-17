# Constitución del proyecto Zoo Zombie

Principios que rigen todas las decisiones de diseño y desarrollo. Las specs, los planes y el código deben cumplirlos. Una excepción solo es válida si se aprueba explícitamente y se registra como ADR en `docs/decisions/`.

**Versión:** 1.0.0 · **Fecha:** 2026-11-16

---

## I. El diseño gira en torno al dilema central

La dificultad del juego nace de **elegir entre combatir y alimentar**. Mientras el jugador carga comida está indefenso. Cualquier mecánica nueva se evalúa con una pregunta: ¿refuerza este dilema o lo diluye? Si lo diluye, no entra.

## II. Primero la spec, después el código

Ningún sistema se implementa sin una spec aprobada que defina sus requisitos y criterios de aceptación. El orden siempre es **spec → plan → tasks → implementación → verificación**.

## III. Todo valor de diseño es configurable

Vida, daño, puntuación, tiempos, cantidades, velocidades y probabilidades se definen en recursos de datos (`Resource` / `.tres`). Ningún número de balance va escrito a mano dentro del código. Así se puede ajustar el juego sin reprogramarlo.

## IV. Sistemas pequeños, independientes y reutilizables

- Cada responsabilidad es un componente o script propio (vida, interacción, transporte, armas, oleadas, puntuación).
- Los sistemas se comunican por **señales**, ya sean locales o del bus global `EventBus`. No se buscan entre sí con rutas de nodos frágiles.
- Una misma funcionalidad nunca se implementa dos veces.

## V. Progreso incremental y verificable

Se trabaja por fases. Cada fase termina con algo jugable o comprobable y se prueba contra sus criterios de aceptación antes de seguir. No se modifica todo el proyecto de golpe.

## VI. Respetar lo que existe

Antes de crear algo se revisa lo existente. No se reemplazan sistemas, escenas, mapas ni modelos sin justificarlo y sin aprobación. Los cambios de arquitectura se explican **antes** de hacerlos.

## VII. Rendimiento low-poly

El juego debe correr fluido en una computadora personal común (objetivo: **60 FPS a 1080p**).

- Los modelos son low-poly y comparten estética: colores planos o paletas simples.
- Las colisiones usan formas simples, no la malla visual.
- La vegetación repetida usa instancias (`MultiMeshInstance3D`).

## VIII. Assets trazables

Todo asset externo se registra en `docs/assets.md` con su fuente, autor y licencia. Solo se usan licencias que permitan uso en videojuegos (CC0, CC-BY o equivalentes). Los modelos procedurales se generan con scripts versionados, uno por modelo.

## IX. Idioma y convenciones

- Código, comentarios y nombres de archivos, nodos y recursos: **inglés**.
- Documentación SDD y mensajes de commit: **español**.
- Commits sin firmas ni menciones de herramientas de IA.

El detalle completo está en `AGENTS.md`.

## X. Comunicación con el usuario

Ante la duda, se pregunta: **máximo 5 preguntas por ronda**, cada una con una opción recomendada. Lo no bloqueante se registra como supuesto en la spec.

---

## Gobernanza

- Para modificar esta constitución hace falta aprobación del usuario y subir la versión (semver: mayor si se elimina o cambia un principio, menor si se agrega uno, parche si son aclaraciones).
- Si una spec o un plan contradice esta constitución, prevalece la constitución.
