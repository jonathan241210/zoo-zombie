# Spec 004: Soltar comida y HUD de alimentación

**Estado:** RF-01 a RF-09, RF-50 y RF-60 a RF-64 aprobados · **Versión:** 0.3 · **Fecha:** 2026-11-19
**Plan:** [`plans/004-food-drop-and-feeding-hud.md`](../plans/004-food-drop-and-feeding-hud.md) · **Tareas:** [`tasks/004-food-drop-and-feeding-hud.md`](../tasks/004-food-drop-and-feeding-hud.md)
**Depende de:** [`specs/001-zoo-survival.md`](001-zoo-survival.md) y [`specs/002-menus-and-onboarding.md`](002-menus-and-onboarding.md)

---

## 1. Resumen

Mejoras de interacción y HUD:

1. El jugador puede **soltar la caja de comida con la misma tecla de interactuar (E)**.
2. El HUD muestra la **vida del jugador** y la **munición actual y de reserva**.
3. El indicador de vida próxima usa relleno verde; el contorno amarillo refleja la saciedad actual y se apaga al vaciarse.
4. Cada **comedero** muestra un **contador de segundos** con el tiempo que le queda a la saturación del animal, para saber cuándo volver a darle de comer.
5. Al acercarse a los animales, el HUD muestra sus barras individuales de vida y saciedad.

El usuario aprobó el descarte de comida (RF-01 a RF-09), los indicadores básicos del jugador (RF-50) y esta barra de vida próxima (RF-60 a RF-64). El resto de los indicadores de alimentación sigue pendiente.

Esta spec **amplía** RF-11, RF-25, RF-101 y RF-108 de la spec 001, y el RF-60 de la spec 002.

## 2. Historias de usuario

- **HU-01:** Como jugador, quiero soltar la caja que cargo para volver a usar mis armas sin tener que alimentar a un animal.
- **HU-02:** Como jugador, quiero ver la vida y la saturación de cada animal de un vistazo, con colores distintos.
- **HU-03:** Como jugador, quiero ver cuántos segundos le quedan de saturación a un animal junto a su comedero, para saber cuándo volver con más comida.

## 3. Requisitos funcionales

### 3.1 Soltar la caja con E

| ID | Requisito |
|---|---|
| RF-01 | Mientras el jugador está **CARGANDO** y **no** está junto a un comedero donde pueda alimentar (RF-25 de la spec 001), pulsar **interactuar (E / A / Cruz)** **suelta la caja** frente a él. |
| RF-02 | Al soltarla, el jugador vuelve al estado **ARMADO** y recupera el arma que tenía equipada (RF-5B de la spec 001). |
| RF-03 | La caja soltada **cae al suelo y permanece ahí**: no desaparece, no regresa a su punto de aparición y no cuenta como caja nueva. Se vuelve a recoger con E (RF-11 de la spec 001). |
| RF-04 | La caja soltada **cuenta para el máximo de cajas activas** (RF-13 de la spec 001), de modo que no se generan más cajas por soltarla. |
| RF-05 | Si el jugador está junto a un comedero **y** puede alimentar, E **alimenta** y no suelta la caja. Soltar siempre es la acción de respaldo. |
| RF-06 | Si no hay espacio libre frente al jugador (pared u obstáculo), la caja se suelta en el punto libre más cercano, sin atravesar la geometría. |
| RF-07 | Soltar la caja tiene animación breve (duración configurable) y un sonido. No se puede disparar durante la animación. |
| RF-08 | La indicación en pantalla muestra **"Soltar (E)"** mientras se carga una caja y no se puede alimentar, con el icono del dispositivo actual (RF-102 de la spec 001). |
| RF-09 | Un animal escapado que sigue al jugador (RF-44 de la spec 001) **deja de seguirlo** al soltar la caja, pues ya no carga comida. |

### 3.2 Indicadores de vida y saciedad

Los requisitos RF-10 a RF-15 describen la presentación extendida pendiente. El indicador próximo RF-60 a RF-64 es el alcance aprobado: la saciedad cambia el color del contorno, no aparece como otra barra de progreso.

| ID | Requisito |
|---|---|
| RF-10 | En la **tarjeta del HUD** de cada animal (RF-101 de la spec 001), la vida usa relleno verde y la saciedad se representa con el color del contorno amarillo; no se agrega una segunda barra de progreso para la saciedad. |
| RF-11 | Cualquier futuro indicador flotante sobre el animal debe conservar la distinción vida/saciedad sin convertir el contorno amarillo en una barra secundaria. |
| RF-12 | La barra de vida cambia de tono según el valor: verde, verde claro con poca vida y **rojo** por debajo del umbral de debilidad (RF-27 de la spec 001). |
| RF-13 | El contorno amarillo representa saciedad: su intensidad baja continuamente al agotarse y la vida empieza a bajar al llegar a 0 (RF-22 y RF-108 de la spec 001). |
| RF-14 | Los indicadores de animales se muestran solo dentro de la distancia configurable y se ocultan si el animal muere. |
| RF-15 | Cada indicador identifica el animal con su nombre y un pequeño icono de corazón; el valor numérico de vida puede añadirse a la futura tarjeta del HUD. |

### 3.3 Duración de la saturación

| ID | Requisito |
|---|---|
| RF-20 | La **duración de la saturación** (tiempo desde que el animal come hasta que empieza a perder vida) es **configurable por animal** en su recurso `.tres`. Es el mismo periodo de gracia del RF-22 de la spec 001. |
| RF-21 | La barra amarilla refleja exactamente ese tiempo: `saturación restante / duración total`. |
| RF-22 | Al alimentar, la saturación se **reinicia a su duración completa** (RF-25 de la spec 001). |
| RF-23 | La saturación **sigue corriendo** aunque el animal esté escapado, aunque el jugador esté muerto o con el mapa abierto sin pausar. Solo se detiene en pausa (RF-23 de la spec 001). |

### 3.4 Contador de segundos en el comedero

| ID | Requisito |
|---|---|
| RF-30 | Sobre el **comedero de cada animal contenido** hay un **contador de segundos** (texto 3D, billboard) que muestra el tiempo restante de saturación de ese animal. Ejemplo: `27 s`. |
| RF-31 | El contador está **siempre visible** y es legible a distancia (tamaño y contorno configurables). |
| RF-32 | El contador pasa a **rojo** (y parpadea) cuando quedan **menos de 10 s** (umbral configurable). |
| RF-33 | Cuando la saturación llega a 0, el contador muestra **`0 s` en rojo** hasta que se alimente al animal. |
| RF-34 | Tras alimentar, el contador **vuelve a la duración completa** (por ejemplo `30 s`) y empieza a bajar. |
| RF-35 | Si el animal **escapa**, el comedero queda inutilizable (RF-33 de la spec 001) y el contador **se oculta**. Cuando el animal es contenido en un refugio, aparece en el **nuevo comedero** (RF-45 de la spec 001). |
| RF-36 | Si el animal **muere**, el contador se oculta. |
| RF-37 | Los textos son claves de traducción, en español e inglés (RF-102 de la spec 002). La unidad se traduce (`s`). |

### 3.5 Controles

| ID | Requisito |
|---|---|
| RF-40 | No se agrega ninguna acción de input nueva: soltar usa la acción existente **`interact`**. Se reasigna junto con ella en la pantalla de Controles (RF-61 de la spec 002). |
| RF-41 | La fila "Interactuar" de la tabla de controles se renombra a **"Interactuar (recoger, alimentar, soltar)"**. |
| RF-42 | **Cómo jugar > Animales y comida** (RF-51 de la spec 002) explica que se puede soltar la caja con E y qué significan las barras verde y amarilla y el contador. |
| RF-43 | Nuevo consejo contextual, una sola vez: **TIP-14**, primera vez que se carga una caja: "Pulsa [E] lejos de un comedero para soltar la caja." |
| RF-50 | El HUD muestra la vida actual/máxima del jugador y el cargador/reserva de munición de la escopeta; se actualiza al cambiar la vida o munición. |
| RF-60 | Al acercarse a un animal vivo, aparece un indicador individual de ese animal; se oculta al salir del radio configurable. Si hay varios animales cerca, aparece un indicador por cada uno. |
| RF-61 | Los indicadores aparecen en el HUD justo encima de la barra de vida del jugador, con diseño compacto y un icono de corazón junto a cada barra. |
| RF-62 | El relleno interior es verde y representa `HealthComponent.current_health / max_health`; se actualiza con las señales de salud, sin depender del efecto del contorno. |
| RF-63 | Un contorno amarillo recorre el perímetro completo de la barra. El amarillo solo se dibuja en el borde: no rellena el interior ni varía como una segunda barra de vida. |
| RF-64 | El contorno amarillo representa la saciedad: empieza intenso cuando está llena y pierde saturación e intensidad progresivamente al bajar. Al alimentar se restablece; cuando llega a cero, empieza el daño gradual a la vida. |

## 4. Valores configurables

Se guardan en recursos `.tres`, nunca en el código.

| Parámetro | Valor inicial | Dónde |
|---|---|---|
| Duración de la saturación, jirafa | 30 s | `AnimalConfig` de la jirafa |
| Duración de la saturación, elefante | 30 s | `AnimalConfig` del elefante |
| Duración de la animación de soltar | 0.3 s | Config del jugador |
| Distancia para ver las barras flotantes | 25 m | `FeedingHudConfig` |
| Umbral del contador en rojo | 10 s | `FeedingHudConfig` |
| Color del relleno de vida / contorno de saciedad | Verde / amarillo | `AnimalHealthHudConfig` |
| Radio para mostrar vida animal en el HUD | 12 m | `AnimalHealthHudConfig` |
| Ancho / alto de la barra compacta | 210 px / 14 px | `AnimalHealthHudConfig` |
| Color del borde con saciedad llena / vacía | Amarillo intenso / oliva apagado | `AnimalHealthHudConfig` |
| Color del contador normal / urgente | Blanco / rojo | `FeedingHudConfig` |

## 5. Criterios de aceptación

- **CA-01:** Cargando una caja y lejos de un comedero, E la suelta frente al jugador, vuelve a ARMADO y puede disparar.
- **CA-02:** Junto a un comedero con alimentación posible, E **alimenta** y no suelta la caja.
- **CA-03:** La caja soltada se recoge de nuevo con E, no desaparece y no genera cajas extra (respeta el máximo de cajas activas).
- **CA-04:** Un animal escapado que seguía al jugador deja de seguirlo al soltar la caja.
- **CA-05:** La vida se muestra con relleno verde y la saciedad se distingue con el contorno amarillo, sin una segunda barra para la saciedad.
- **CA-06:** Tras alimentar, el borde vuelve a amarillo intenso y se apaga durante el periodo configurable; al agotarse, empieza a bajar la vida.
- **CA-07:** El comedero de cada animal muestra el contador en segundos, que baja cada segundo y coincide con la barra amarilla.
- **CA-08:** El contador se pone rojo y parpadea con menos de 10 s, se reinicia al alimentar y se oculta si el animal escapa o muere.
- **CA-09:** Al cambiar la duración de saturación en un `AnimalConfig`, la barra y el contador la reflejan sin tocar el código.
- **CA-10:** La pantalla de Controles muestra "Interactuar (recoger, alimentar, soltar)" y la reasignación de `interact` también afecta soltar.
- **CA-11:** Todo funciona con teclado y mouse y con gamepad.
- **CA-12:** Al entrar dentro del radio de un animal vivo aparece su fila sobre la barra de vida del jugador, con corazón; fuera del radio se oculta.
- **CA-13:** Si hay más de un animal dentro del radio, cada uno muestra su propio indicador y su propia vida actual.
- **CA-14:** La vida se muestra como relleno verde real y el contorno amarillo permanece alrededor del perímetro completo; el amarillo nunca funciona como progreso de vida.
- **CA-15:** El borde inicia intenso, se apaga suave y gradualmente al bajar la saciedad y vuelve a intenso al alimentar; no depende de la vida.

## 6. Fuera de alcance

- Lanzar la caja a distancia o arrojarla a otro animal.
- Que la caja soltada se dañe, se pudra o la roben los zombis.
- Cantidades de comida distintas por caja.
- Una nueva acción de input para soltar (se reutiliza `interact`).

## 7. Supuestos y preguntas abiertas

| ID | Tema | Decisión | Estado |
|---|---|---|---|
| D-01 | Dónde van las barras | HUD y flotando sobre el animal | ✅ Confirmado (2026-11-18) |
| D-02 | Qué pasa con la caja soltada | Cae al suelo, se puede recoger de nuevo y no desaparece | ✅ Confirmado (2026-11-18) |
| D-03 | Qué cuenta el contador | Segundos restantes de saturación (periodo de gracia) | ✅ Confirmado (2026-11-18) |
| D-04 | Duración de la saturación | 30 s para ambos, configurable por animal | ✅ Confirmado (2026-11-18) |
| D-05 | Visibilidad del contador | Siempre visible, rojo con menos de 10 s | ✅ Confirmado (2026-11-18) |
| S-01 | Prioridad de E | Alimentar tiene prioridad sobre soltar junto a un comedero | Supuesto |
| S-02 | Caja soltada y máximo de cajas activas | Cuenta para el máximo, así no se generan más cajas | Supuesto |
| S-03 | Animal que seguía al jugador | Deja de seguirlo al soltar la caja | Supuesto |
| S-04 | Barras flotantes | Solo se ven a menos de 25 m | Supuesto |
| S-05 | Saciedad inicial | Empieza llena al iniciar la partida para dar el periodo de gracia configurado; los comederos visualmente empiezan vacíos | Supuesto documentado para validar |
