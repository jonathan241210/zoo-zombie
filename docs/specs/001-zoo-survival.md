# Spec 001: Supervivencia en el zoológico

**Estado:** Borrador, pendiente de aprobación · **Versión:** 0.2 · **Fecha:** 2026-11-16
**Plan:** [`plans/001-zoo-survival.md`](../plans/001-zoo-survival.md) · **Tareas:** [`tasks/001-zoo-survival.md`](../tasks/001-zoo-survival.md)

---

## 1. Resumen

Videojuego 3D de supervivencia **en primera persona** ambientado en un zoológico abandonado e infestado de zombis. El jugador debe sobrevivir a **tres oleadas** mientras mantiene con vida a dos animales, una **jirafa** y un **elefante**, que están en recintos distintos.

- Los animales **pierden vida por hambre**: el jugador debe llevarles cajas de comida, y mientras carga una caja **no puede disparar**.
- Los zombis pueden **atacar los recintos**. Si destruyen uno, el animal **escapa**, huye corriendo hasta agotarse y queda expuesto a los zombis. El jugador debe **atraerlo con comida** hasta otro recinto libre.
- Si un animal muere, **se zombifica**: aparece una horda extra de zombis.

La dificultad nace de un dilema constante: **combatir, alimentar o rescatar**.

## 2. Objetivos

1. Defenderse de los zombis con una escopeta de munición limitada.
2. Conseguir y transportar alimento hasta los recintos.
3. Proteger los recintos y recapturar a los animales que escapen.
4. Mantener vivos a los animales durante las tres oleadas.

**Victoria:** completar las 3 oleadas con **al menos un animal vivo**.
**Derrota:** **ambos** animales mueren.

## 3. Plataforma y controles

- PC (macOS y Windows), con teclado y mouse y también con control (gamepad).
- El jugador **no puede saltar**.

| Acción | Teclado/Mouse | Gamepad |
|---|---|---|
| Moverse | WASD | Stick izquierdo |
| Mirar | Mouse | Stick derecho |
| Disparar / golpear | Clic izquierdo | RT / R2 |
| Recargar | R | X / Cuadrado |
| Cambiar arma (escopeta ↔ hacha) | Q / rueda del mouse / 1-2 | Y / Triángulo |
| Interactuar (recoger / alimentar) | E | A / Cruz |
| Correr | Shift | L3 |
| Pausa | Esc | Start / Options |

## 4. Historias de usuario

- **HU-01:** Como jugador, quiero moverme y mirar en primera persona por el zoológico para explorarlo y encontrar recursos.
- **HU-02:** Como jugador, quiero disparar la escopeta y recargarla para defenderme de los zombis.
- **HU-03:** Como jugador, quiero recoger cajas de alimento y llevarlas a los recintos para alimentar a los animales.
- **HU-04:** Como jugador, quiero ver la vida de cada animal y el estado de su recinto para decidir qué atender primero.
- **HU-05:** Como jugador, quiero recoger la munición que sueltan los zombis para seguir combatiendo.
- **HU-06:** Como jugador, quiero reaparecer al morir sin perder la partida, para seguir protegiendo a los animales.
- **HU-07:** Como jugador, quiero ver la oleada actual, el tiempo y mi puntaje para saber cómo voy.
- **HU-08:** Como jugador, quiero atraer con comida a un animal que escapó y llevarlo a otro recinto para salvarlo.
- **HU-09:** Como jugador, quiero una pantalla de victoria o derrota con estadísticas al terminar la partida.

## 5. Requisitos funcionales

### 5.1 Jugador (primera persona)

| ID | Requisito |
|---|---|
| RF-01 | El jugador se mueve en primera persona con cámara libre (mouse o stick). Puede caminar y correr. **No puede saltar.** |
| RF-02 | El jugador tiene vida máxima configurable. Recibe daño de los zombis. |
| RF-03 | La vista en primera persona muestra los brazos con el arma equipada (escopeta o hacha), o con la caja cuando la está cargando. |
| RF-04 | El jugador tiene dos estados exclusivos: **ARMADO** y **CARGANDO**. |
| RF-05 | Mientras está **CARGANDO**: no puede disparar, recargar, usar el hacha ni cambiar de arma; se ve la animación de transporte, se mueve más lento (velocidad configurable) y los zombis siguen atacándolo. |
| RF-06 | El jugador aparece al inicio, y reaparece al morir, junto a `EST_CAFETERIA`. |

### 5.2 Cajas de alimento

| ID | Requisito |
|---|---|
| RF-10 | Hay cajas de alimento en varios puntos de aparición del mapa, configurables. |
| RF-11 | Al acercarse a una caja aparece la indicación "Recoger (E)". Al interactuar, el jugador la toma y pasa a **CARGANDO**. |
| RF-12 | Solo se puede cargar una caja a la vez. **Cualquier caja sirve para cualquier animal.** |
| RF-13 | Cuando se recoge una caja, su punto de aparición genera otra después de un tiempo configurable. Hay un máximo configurable de cajas activas en el mapa. |
| RF-14 | Si el jugador muere mientras carga una caja, la caja **se pierde**. Su punto de aparición vuelve a generarla después del tiempo configurado. |

### 5.3 Animales: hambre y alimentación

| ID | Requisito |
|---|---|
| RF-20 | Hay dos animales al inicio: **jirafa** en `REC_RECINTO_RUSTICO_M4_DIAGONAL` y **elefante** en `REC_RECINTO_RUSTICO_M2_CENTRO_NORTE`. Se podrán agregar más animales después. |
| RF-21 | Cada animal tiene vida máxima, vida actual y un temporizador de inanición. |
| RF-22 | Después de comer, el animal tiene un **periodo de gracia** configurable sin perder vida por hambre. Al terminar ese periodo, pierde vida de forma continua a una tasa configurable (vida por segundo). |
| RF-23 | El temporizador de inanición corre durante **toda la partida**, aunque el animal esté escapado y aunque el jugador esté muerto. Solo se detiene en pausa. |
| RF-24 | Cada animal tiene su propio **comedero**, que siempre está en el recinto donde el animal vive en ese momento. El de la jirafa es elevado, sobre un poste o soporte alto; el del elefante es bajo, a nivel del suelo. |
| RF-25 | Si el jugador está **CARGANDO** cerca del comedero de un animal contenido, aparece la indicación "Alimentar (E)". Al interactuar: la caja se consume, el animal recupera vida (cantidad configurable, sin pasar del máximo), se reinicia su temporizador de inanición, se reproduce la animación de comer, se suman puntos y el jugador vuelve a **ARMADO**. |
| RF-26 | Un animal escapado **no se puede alimentar** hasta que vuelva a estar en un recinto. |
| RF-27 | Cuando la vida del animal baja de un umbral configurable (% de vida), pasa al estado **DÉBIL**: animación propia, movimiento más lento y alerta en el HUD. |

### 5.4 Recintos destructibles

| ID | Requisito |
|---|---|
| RF-30 | Cada recinto ocupado por un animal tiene **integridad** (vida del recinto), con máximo configurable. |
| RF-31 | Mientras el recinto esté intacto, los zombis **no pueden entrar** ni dañar al animal que está dentro. |
| RF-32 | Los zombis pueden golpear el recinto (daño y frecuencia configurables). Al llegar a 0 de integridad, el recinto queda **destruido** durante el resto de la partida: no se puede reparar. |
| RF-33 | Al destruirse el recinto, el animal **escapa** (ver 5.5). Su comedero queda inutilizable hasta que el animal tenga un nuevo recinto. |
| RF-34 | Hay **recintos de refugio**: una lista configurable de recintos libres que pueden recibir a un animal escapado. Un refugio ocupado se comporta como cualquier recinto: tiene integridad y los zombis pueden atacarlo. |
| RF-35 | Un recinto solo puede contener un animal a la vez. |

### 5.5 Animales escapados y recaptura

| ID | Requisito |
|---|---|
| RF-40 | Un animal escapado **huye corriendo** de los zombis cercanos (animación de correr). |
| RF-41 | El animal tiene **resistencia** (stamina). Correr la gasta; caminar o descansar la recupera, a tasas configurables. |
| RF-42 | Si la resistencia llega a 0, el animal queda **CANSADO**: solo camina despacio hasta recuperar un porcentaje configurable de resistencia. Un animal cansado es más lento que los zombis, que pueden alcanzarlo. |
| RF-43 | Los zombis **pueden atacar a un animal escapado** (daño configurable). |
| RF-44 | **Atraer con comida:** si el jugador está **CARGANDO** dentro de un radio configurable de un animal escapado, el animal lo **sigue** a su velocidad de caminar, manteniendo una distancia mínima. Si el jugador se aleja más de un radio máximo, el animal deja de seguirlo. Mientras sigue al jugador, el animal no huye. |
| RF-45 | Cuando un animal que sigue al jugador entra en un **refugio libre e intacto**, queda **contenido** ahí: ese recinto pasa a ser su hogar, su comedero aparece en ese recinto, y el jugador puede alimentarlo de inmediato con la caja que carga. |
| RF-46 | Un HUD o marcador indica dónde está cada animal escapado y cuáles son los refugios libres. |

### 5.6 Muerte de un animal (zombificación)

| ID | Requisito |
|---|---|
| RF-47 | Si un animal llega a 0 de vida, por hambre o por ataques, **muere** y **se zombifica**: aparece una horda extra de zombis (cantidad configurable) en su posición. |
| RF-48 | La muerte de un animal resta puntos (penalización configurable) y deja ese animal fuera del resto de la partida. |
| RF-49 | Si mueren **ambos** animales, la partida termina en **derrota**. |

### 5.7 Combate: escopeta, hacha y munición

| ID | Requisito |
|---|---|
| RF-50 | La escopeta dispara varios perdigones con dispersión. Cada perdigón hace daño configurable y tiene alcance máximo. |
| RF-51 | Tiene cargador (capacidad configurable) y reserva de munición (inicial y máxima configurables). |
| RF-52 | La recarga tiene animación y duración configurables. No se puede disparar mientras se recarga. |
| RF-53 | Cada disparo tiene animación, fogonazo, retroceso de cámara y sonido. Al impactar un zombi hay respuesta visual. |
| RF-54 | Los disparos tienen cadencia limitada (tiempo mínimo entre disparos configurable). |
| RF-55 | Al morir, un zombi puede soltar una caja de munición (probabilidad y cantidad configurables). |
| RF-56 | El jugador recoge la munición automáticamente al pasar sobre ella, si su reserva no está llena. La recogida no da puntos en principio (configurable). |
| RF-57 | La munición soltada desaparece después de un tiempo configurable. |
| RF-58 | **Munición en el mapa:** hay una lista configurable de puntos candidatos. Al iniciar la partida se eligen al azar algunos de ellos (cantidad activa configurable) y se coloca una caja de munición en cada uno. Al recogerla, después de un tiempo configurable aparece otra en un punto candidato libre elegido al azar, distinto del anterior. |
| RF-59 | Los puntos de munición están en lugares **poco obvios**: detrás de estructuras, junto a bancas, en esquinas o dentro de kioscos, y no en medio de los caminos principales. Cada caja emite una **luz suave de color con pulso** y un brillo que se distinguen a distancia (alcance configurable), para que el jugador pueda encontrarla si explora. |
| RF-5A | **Hacha (arma secundaria):** uso **ilimitado**, sin munición ni desgaste. Hace daño medio en un **arco frontal** de corto alcance y puede golpear a varios zombis por golpe (máximo configurable). Es lenta (tiempo entre golpes configurable) y provoca un pequeño retroceso en los zombis golpeados. |
| RF-5B | El jugador cambia entre escopeta y hacha con una animación breve (duración configurable). Al recoger una caja se guarda el arma; al alimentar, vuelve el arma que tenía equipada. |
| RF-5C | El golpe del hacha tiene animación, sonido y respuesta visual al impactar. |

### 5.8 Zombis

| ID | Requisito |
|---|---|
| RF-60 | Cada zombi tiene un **rol** asignado al aparecer: **cazador** (va tras el jugador) o **destructor** (va hacia el recinto ocupado más cercano). La proporción de destructores es configurable por oleada. |
| RF-61 | Un destructor cambia su objetivo al jugador si recibe daño o si el jugador se acerca a menos de un radio configurable. |
| RF-62 | Cualquier zombi ataca a un animal escapado que esté dentro de su radio de detección. |
| RF-63 | Los zombis detectan al jugador dentro de un radio configurable, con línea de visión. Los que aparecen durante una oleada ya conocen su objetivo. |
| RF-64 | Navegan por el zoológico y esquivan obstáculos (navmesh). |
| RF-65 | Atacan cuerpo a cuerpo dentro de un rango, con daño y frecuencia configurables. Atacan al jugador también mientras carga una caja. |
| RF-66 | Tienen vida configurable, reciben daño de la escopeta y del hacha, y mueren al llegar a 0. |
| RF-67 | Tienen animaciones de caminar, correr, atacar, recibir golpe y morir. |
| RF-68 | El cuerpo de un zombi muerto desaparece después de un tiempo configurable. |

### 5.9 Oleadas

| ID | Requisito |
|---|---|
| RF-70 | La partida tiene exactamente **3 oleadas**. |
| RF-71 | Cada oleada define: duración de supervivencia, cantidad total de zombis, intervalo entre apariciones, máximo de zombis vivos a la vez, proporción de destructores y multiplicadores de dificultad (velocidad, vida y daño). |
| RF-72 | La oleada termina cuando se acaba su tiempo. Entre oleadas hay un descanso configurable sin nuevas apariciones. **Los zombis vivos siguen activos** en el descanso y en la siguiente oleada, y cuentan para el máximo de vivos. |
| RF-73 | La dificultad aumenta: la oleada 1 es moderada, la 2 trae más zombis y más presión, y la 3 es la final y la más difícil. |
| RF-74 | Los zombis aparecen en puntos configurables del perímetro del zoológico, lejos del jugador. |
| RF-75 | Los zombis de la horda de zombificación (RF-47) no cuentan para el total de la oleada, pero sí para el máximo de vivos. |
| RF-76 | Al terminar la oleada 3 con al menos un animal vivo, se gana la partida. |

### 5.10 Muerte y reaparición del jugador

| ID | Requisito |
|---|---|
| RF-80 | Si la vida del jugador llega a 0, este reaparece junto a `EST_CAFETERIA` después de un retraso configurable. |
| RF-81 | Al reaparecer recupera toda su vida y se le resta una penalización configurable al puntaje (el mínimo es 0). |
| RF-82 | Se conserva todo el progreso de la partida: oleada, tiempo, estado de los animales y de los recintos, zombis activos y puntaje. |
| RF-83 | La muerte del jugador **no** termina la partida. |

### 5.11 Puntuación

| ID | Requisito |
|---|---|
| RF-90 | Se suman puntos (configurables) por alimentar a la jirafa, alimentar al elefante, eliminar un zombi y **recapturar a un animal escapado**. |
| RF-91 | Se restan puntos (configurables) por muerte del jugador y por muerte de un animal. El puntaje nunca baja de 0. |
| RF-92 | Recoger munición no da puntos en principio (valor configurable, por defecto 0). |
| RF-93 | Se registran estas estadísticas: zombis eliminados, veces que se alimentó a cada animal, recintos destruidos, recapturas, muertes del jugador y tiempo de supervivencia. |

### 5.12 HUD y pantallas

| ID | Requisito |
|---|---|
| RF-100 | El HUD muestra: vida del jugador, munición (cargador / reserva), puntaje, oleada (1/3, 2/3, 3/3), tiempo de supervivencia e indicador de transporte de alimento. |
| RF-101 | Por cada animal hay una tarjeta con: **barra de vida**, **barra de alimento** (saciedad), **barra de integridad de su recinto** y estado (**contenido**, **débil**, **escapado**, **cansado**, **siguiéndote** o **muerto**). |
| RF-108 | La **barra de alimento** está llena justo después de comer y se vacía durante el periodo de gracia (RF-22). Cuando llega a 0, parpadea en rojo y la vida empieza a bajar. Así el jugador ve qué animal necesita comida antes de que pierda vida. |
| RF-10A | **Contador de zombis** junto a la oleada: zombis **vivos** en el mapa y zombis que **faltan por aparecer** en la oleada actual (ej. `Zombis: 7 · Faltan 11`). Los zombis de una horda de zombificación cuentan como vivos. Durante el descanso solo se muestran los vivos. |
| RF-109 | El HUD muestra el icono del arma equipada. Con la escopeta, la munición aparece como `cargador / reserva`; con el hacha, como `∞`. Cuando el cargador está vacío o la reserva está baja (umbral configurable), cambia de color. |
| RF-102 | Hay indicaciones contextuales: "Recoger (E)" junto a una caja y "Alimentar (E)" junto al comedero mientras se carga una caja. El icono cambia según el dispositivo: teclado o gamepad. |
| RF-103 | Hay avisos visuales al empezar cada oleada, al iniciar el descanso, cuando un recinto está bajo ataque, cuando un recinto se destruye y cuando un animal muere. |
| RF-104 | Hay marcadores en pantalla, o en una brújula, hacia los animales escapados y hacia los refugios libres. |
| RF-105 | **Pantalla de victoria:** puntaje total, zombis eliminados, veces que se alimentó a cada animal, recapturas, estado final de cada animal y tiempo de supervivencia. |
| RF-106 | **Pantalla de derrota:** indica que ambos animales murieron, además del puntaje y las estadísticas. |
| RF-107 | Ambas pantallas permiten reiniciar la partida o salir. Hay menú de pausa: continuar, reiniciar y salir. Los menús, la configuración y las instrucciones se detallan en la [spec 002](002-menus-and-onboarding.md). |

### 5.13 Modelos 3D y animaciones

| ID | Requisito |
|---|---|
| RF-110 | Se **priorizan los modelos descargados que ya tienen animaciones** (ver `docs/assets.md`). Se exportan e importan en **GLB**. |
| RF-111 | Las animaciones que falten se crean en Blender por script, o en Godot por código (Tween) si son simples. Lista de animaciones faltantes: debilidad y muerte de la jirafa y del elefante, y recarga de la escopeta. |
| RF-112 | Los modelos que no existan descargados se generan con **scripts Python en Blender**: un script por modelo, con utilidades comunes. Son la caja de alimento, la caja de munición y los dos comederos. |
| RF-113 | Animaciones necesarias por modelo: **animales**: reposo, caminar, correr, comer, débil y muerte. **Zombi**: caminar, correr, atacar, recibir golpe y morir. **Brazos en primera persona**: reposo, disparo, recarga, sacar arma, sostener caja y golpe de hacha. El golpe reutiliza la animación `E_Martillo` del rig de brazos, con `hacha.glb` sujeta a la mano. |

## 6. Valores configurables (valores iniciales sugeridos)

Son valores de partida para el balance. Se ajustan probando el juego.

### Jugador
| Parámetro | Valor |
|---|---|
| Vida máxima | 100 |
| Velocidad caminando / corriendo / cargando | 4.5 / 7.0 / 3.2 m/s |
| Retraso de reaparición | 3 s |
| Penalización por muerte | 100 pts |

### Escopeta
| Parámetro | Valor |
|---|---|
| Capacidad del cargador | 6 |
| Reserva inicial / máxima | 24 / 48 |
| Perdigones por disparo | 8 |
| Daño por perdigón | 12 |
| Dispersión | 6° |
| Alcance | 30 m |
| Tiempo entre disparos | 0.8 s |
| Duración de la recarga | 2.5 s |

### Hacha
| Parámetro | Valor |
|---|---|
| Daño por golpe | 40 (3 golpes en la oleada 1) |
| Alcance / ángulo del arco | 2.2 m / 90° |
| Zombis máximos por golpe | 2 |
| Tiempo entre golpes | 0.9 s |
| Retroceso en los zombis | 1.0 m |
| Tiempo para cambiar de arma | 0.4 s |

### Munición en el mapa
| Parámetro | Valor |
|---|---|
| Puntos candidatos | 15 (se definen en la Fase 5 recorriendo el mapa) |
| Cajas activas a la vez | 4 |
| Cartuchos por caja | 6 |
| Tiempo de reaparición tras recogerla | 45 s |
| Alcance visible de la luz | ~20 m |

### Zombi (base, antes de los multiplicadores de oleada)
| Parámetro | Valor |
|---|---|
| Vida | 100 |
| Velocidad caminando / corriendo | 2.5 / 4.0 m/s |
| Daño al jugador / al animal / al recinto | 10 / 8 / 15 por golpe |
| Frecuencia de ataque | 1 golpe cada 1.2 s |
| Rango de ataque | 1.6 m |
| Radio de detección | 25 m |
| Radio de cambio de objetivo de un destructor al jugador | 6 m |
| Probabilidad de soltar munición / cantidad | 35 % / 4 cartuchos |
| Tiempo hasta que desaparece el cuerpo | 8 s |

### Animales
| Parámetro | Jirafa | Elefante |
|---|---|---|
| Vida máxima | 100 | 140 |
| Periodo de gracia tras comer | 30 s | 30 s |
| Pérdida de vida tras la gracia | 0.8 /s | 0.8 /s |
| Vida recuperada por caja | 50 | 60 |
| Umbral de debilidad | 30 % | 30 % |
| Velocidad caminando / corriendo / cansado | 2.0 / 6.5 / 1.2 m/s | 1.8 / 5.5 / 1.0 m/s |
| Resistencia máxima | 100 | 100 |
| Gasto de resistencia al correr / recuperación | 15 /s / 10 /s | 18 /s / 8 /s |
| Resistencia para dejar de estar cansado | 50 % | 50 % |
| Radio de atracción / radio máximo de seguimiento | 8 m / 15 m | 8 m / 15 m |
| Puntos por alimentar | 150 | 150 |
| Horda al morir (zombis extra) | 6 | 8 |

### Recintos
| Parámetro | Valor |
|---|---|
| Integridad máxima | 300 |
| Refugios disponibles | `REC_ESTANQUE_1`, `REC_RECINTO_RUSTICO_M5_CENTRO_SUR`, `REC_RECINTO_NORTE_CENTRAL` |

### Cajas de alimento
| Parámetro | Valor |
|---|---|
| Puntos de aparición | 6 |
| Máximo de cajas activas | 3 |
| Tiempo de reaparición | 20 s |

### Oleadas
| Parámetro | Oleada 1 | Oleada 2 | Oleada 3 |
|---|---|---|---|
| Duración | 120 s | 150 s | 180 s |
| Zombis totales | 10 | 18 | 30 |
| Intervalo de aparición | 8 s | 6 s | 4 s |
| Máximo vivos a la vez | 6 | 10 | 16 |
| Proporción de destructores | 20 % | 30 % | 40 % |
| Multiplicador de velocidad / vida / daño | 1.0 / 1.0 / 1.0 | 1.15 / 1.1 / 1.1 | 1.3 / 1.2 / 1.25 |

- Descanso entre oleadas: **15 s**.

### Puntuación
| Acción | Puntos |
|---|---:|
| Alimentar a la jirafa / al elefante | +150 / +150 |
| Eliminar un zombi | +25 |
| Recapturar un animal | +200 |
| Recoger munición | 0 |
| Muerte del jugador | −100 |
| Muerte de un animal | −300 |

## 7. Criterios de aceptación

- **CA-01:** Con una caja en las manos, al pulsar disparar o recargar no pasa nada. Al alimentar, el jugador vuelve a poder disparar.
- **CA-02:** Si no se alimenta a un animal, su vida empieza a bajar al terminar el periodo de gracia, pasa a **débil** al cruzar el umbral y llega a 0 en el tiempo esperado según la configuración.
- **CA-03:** Al alimentar a un animal, su vida sube según lo configurado (sin pasar del máximo), su temporizador se reinicia y se suman los puntos correctos.
- **CA-04:** Los destructores dañan el recinto. Al llegar a 0, el recinto queda destruido y el animal escapa corriendo.
- **CA-05:** El animal escapado se cansa al correr, se vuelve más lento y los zombis pueden alcanzarlo y dañarlo.
- **CA-06:** Con una caja en las manos, el animal escapado sigue al jugador. Al entrar a un refugio libre queda contenido, su comedero aparece ahí y se puede alimentar.
- **CA-07:** Si un animal muere, aparece la horda extra en su posición y la partida continúa. Si mueren ambos, aparece la pantalla de derrota.
- **CA-08:** Si el jugador muere, reaparece junto a la cafetería con vida completa, se aplica la penalización y todo lo demás sigue igual.
- **CA-09:** Hay exactamente 3 oleadas, cada una con sus valores configurados. El HUD muestra 1/3, 2/3 y 3/3, y los zombis vivos pasan de una oleada a otra.
- **CA-10:** Al terminar la oleada 3 con al menos un animal vivo aparece la pantalla de victoria con todas las estadísticas.
- **CA-11:** Los zombis rodean obstáculos para llegar a su objetivo y atacan al jugador aunque cargue una caja.
- **CA-12:** La munición se agota y se repone con la que sueltan los zombis y con las cajas del mapa. Nunca supera la reserva máxima. Las cajas del mapa aparecen en puntos aleatorios y se distinguen por su luz.
- **CA-16:** El hacha se puede usar sin límite, golpea hasta 2 zombis por golpe con el daño configurado y no se puede usar mientras se carga una caja.
- **CA-13:** Todos los valores de la sección 6 se pueden cambiar en recursos `.tres` sin tocar el código.
- **CA-14:** El juego se puede jugar completo tanto con teclado y mouse como con gamepad.
- **CA-15:** El juego mantiene 60 FPS a 1080p en la máquina de desarrollo (Mac) con el máximo de zombis vivos.

## 8. Fuera de alcance (por ahora)

- Multijugador.
- Armas distintas de la escopeta y el hacha. El modelo `brazos_ametralladora.glb` queda reservado para una versión futura.
- Power-ups (por ejemplo, un modo "furia" del hacha).
- Reparar recintos destruidos.
- Más de dos animales. Es fácil agregarlos después: solo hace falta un `AnimalConfig` nuevo y un modelo.
- Perro zombi como enemigo (`zombie_dog_animation.glb`): queda reservado para una versión futura.
- Guardado de partida a mitad del juego.

## 9. Supuestos y decisiones

| ID | Tema | Decisión | Estado |
|---|---|---|---|
| D-01 | Cámara | Primera persona | ✅ Confirmado |
| D-02 | Recinto de la jirafa | `REC_RECINTO_RUSTICO_M4_DIAGONAL` | ✅ Confirmado |
| D-03 | Plataforma | PC, teclado y mouse + gamepad | ✅ Confirmado |
| D-04 | Modelos | Se priorizan los descargados que ya tienen animaciones; lo que falte se hace con código | ✅ Confirmado |
| D-05 | Animales | Jirafa y **elefante** (reemplaza al hipopótamo porque hay modelo animado). Se agregarán más después | ✅ Confirmado |
| D-06 | Recinto del elefante | `REC_RECINTO_RUSTICO_M2_CENTRO_NORTE` | ✅ Confirmado |
| D-07 | Los zombis atacan recintos y animales | Sí. Recinto destruido → el animal escapa → se recaptura atrayéndolo con comida a un refugio | ✅ Confirmado |
| D-08 | Muerte de un animal | Se zombifica (horda extra) y la partida sigue. Derrota solo si mueren ambos | ✅ Confirmado |
| D-09 | Reparar recintos | No. Se usa otro recinto (refugio) | ✅ Confirmado |
| D-10 | Tipo de comida | Cualquier caja sirve para cualquier animal | ✅ Confirmado |
| D-11 | Zombis al terminar una oleada | Siguen activos en la siguiente | ✅ Confirmado |
| D-12 | Salto | El jugador no puede saltar | ✅ Confirmado |
| D-13 | Punto de aparición del jugador | Junto a `EST_CAFETERIA` | ✅ Confirmado |
| D-14 | Hacha | Arma secundaria ilimitada, con daño medio en arco | ✅ Confirmado |
| D-15 | Munición en el mapa | Puntos aleatorios poco obvios, señalados con una luz | ✅ Confirmado |
| S-01 | Refugios disponibles | `REC_ESTANQUE_1`, `REC_RECINTO_RUSTICO_M5_CENTRO_SUR` y `REC_RECINTO_NORTE_CENTRAL` (configurable) | Supuesto |
| S-02 | Roles de los zombis | Cazador / destructor, con proporción configurable por oleada | Supuesto |
| S-03 | La atracción con comida es automática | El animal sigue al jugador si este carga una caja dentro del radio de atracción. No requiere pulsar ningún botón | Supuesto |
