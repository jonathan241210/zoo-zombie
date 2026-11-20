# Spec 002: Menús, configuración e instrucciones

**Estado:** Ampliación de Controles y tutorial breve aprobados; tutorial implementado; verificación pendiente; resto en borrador · **Versión:** 0.5 · **Fecha:** 2026-11-20
**Plan:** [`plans/002-menus-and-onboarding.md`](../plans/002-menus-and-onboarding.md) · **Tareas:** [`tasks/002-menus-and-onboarding.md`](../tasks/002-menus-and-onboarding.md)
**Depende de:** [`specs/001-zoo-survival.md`](001-zoo-survival.md)

---

## 1. Resumen

Todo lo que rodea a la partida y le explica al jugador **qué hacer y cómo hacerlo**:

- Menú principal, menú de pausa y pantallas de carga y créditos.
- Configuración de gráficos, audio, controles y accesibilidad.
- Pantalla de **Cómo jugar**, con las reglas del juego: animales, comida, recintos, armas y oleadas.
- Pantalla de **controles** para consultar todas las teclas y botones que usa el juego. En esta versión es informativa: no permite reasignar controles.
- **Instrucciones dentro del juego**: un tutorial breve antes de empezar, consejos contextuales la primera vez que ocurre algo y anuncios de oleada.

El objetivo es que un jugador nuevo entienda el dilema central (**combatir, alimentar o rescatar**) en sus primeros minutos, sin leer un manual.

## 2. Historias de usuario

- **HU-01:** Como jugador nuevo, quiero que el juego me explique el objetivo antes de empezar, para saber qué debo proteger.
- **HU-02:** Como jugador nuevo, quiero consejos en pantalla la primera vez que pasa algo importante (una caja cerca, un animal con hambre, un recinto atacado), para aprender jugando.
- **HU-03:** Como jugador, quiero consultar las reglas y los controles cuando quiera, desde el menú principal o desde la pausa.
- **HU-04:** Como jugador, quiero ajustar gráficos, audio, sensibilidad y teclas, y que el juego recuerde mi configuración.
- **HU-05:** Como jugador con control (gamepad), quiero navegar todos los menús sin mouse y ver los iconos de mi control.
- **HU-06:** Como jugador con experiencia, quiero desactivar los consejos.

## 3. Flujo de pantallas

```
Inicio del juego
   └─► Pantalla de título ("Presiona cualquier tecla")
         └─► Menú principal
               ├─► Jugar ──► Partida pausada + tutorial breve ──► Comenzar ──► Oleada 1
               │                                                   ├─► Pausa ──► (Continuar | Cómo jugar | Controles | Configuración | Reiniciar | Salir al menú)
               │                                                   └─► Victoria / Derrota ──► (Reiniciar | Menú principal)
               ├─► Cómo jugar
               ├─► Controles
               ├─► Configuración
               ├─► Créditos
               └─► Salir
```

## 4. Requisitos funcionales

### 4.1 Pantalla de título y menú principal

| ID | Requisito |
|---|---|
| RF-01 | Al abrir el juego aparece una **pantalla de título** con el logo "Zoo Zombie" sobre una escena de fondo del zoológico (cámara lenta recorriendo el mapa) y el texto "Presiona cualquier tecla" (o "Presiona cualquier botón" si se usa un control). |
| RF-02 | El **menú principal** tiene estas opciones: **Jugar**, **Cómo jugar**, **Controles**, **Configuración**, **Créditos** y **Salir**. |
| RF-03 | Al elegir **Jugar**, se abre una ventana emergente con el tutorial breve antes de iniciar las oleadas. No se muestra una pregunta previa ni se abre la pantalla extensa de Cómo jugar. |
| RF-04 | La opción **Salir** pide confirmación. |

### 4.2 Pantalla de carga

| ID | Requisito |
|---|---|
| RF-10 | Mientras carga la partida se muestra una pantalla con barra de progreso y un **consejo aleatorio** de la lista de consejos (sección 6). |
| RF-11 | La carga se hace en segundo plano: la pantalla no se congela. |

### 4.3 Tutorial breve (antes de empezar)

| ID | Requisito |
|---|---|
| RF-20 | Al cargar la partida aparece una ventana emergente compacta, con el juego pausado detrás. Informa que hay dos animales (jirafa y elefante), que hay cajas de comida en el mapa y que el jugador debe alimentarlos y evitar que mueran de hambre o los maten los zombis. |
| RF-21 | El texto del tutorial es breve, de una sola pantalla, y está disponible en español e inglés mediante el sistema de traducciones. |
| RF-22 | Un botón visible **Comenzar** cierra la ventana y después inicia la cuenta regresiva configurable antes de las oleadas. Hasta entonces no aparecen ni se activan zombis. |
| RF-23 | El tutorial aparece al iniciar cada partida nueva y el jugador puede continuar cuando termine de leerlo. |

### 4.4 Consejos contextuales (tutorial integrado)

| ID | Requisito |
|---|---|
| RF-30 | Hay **consejos contextuales**: mensajes breves en pantalla (máximo ~15 palabras), con el icono de la tecla o botón correspondiente, que aparecen **la primera vez** que ocurre un evento (lista en la sección 6). |
| RF-31 | Cada consejo se muestra una sola vez por perfil. Su estado se guarda entre partidas. |
| RF-32 | Los consejos no pausan el juego. Duran un tiempo configurable (6 s por defecto), o hasta que el jugador realiza la acción sugerida. |
| RF-33 | Solo se muestra un consejo a la vez. Si se acumulan, entran en cola con prioridad: los de peligro (animal en peligro, recinto atacado) van primero. |
| RF-34 | En **Configuración** se pueden desactivar los consejos y también reiniciarlos ("Reiniciar consejos"). |

### 4.5 Anuncios de oleada

Estos requisitos amplían el RF-103 de la spec 001.

| ID | Requisito |
|---|---|
| RF-40 | Al iniciar una oleada aparece un anuncio grande y centrado durante 3 s: "OLEADA 2/3" + subtítulo ("Más zombis, más destructores") + sonido de alerta. |
| RF-41 | Durante el descanso entre oleadas aparece "Descanso: siguiente oleada en 15" con cuenta regresiva y **un consejo** de la lista general. |
| RF-42 | Al empezar la oleada final, el anuncio dice "OLEADA FINAL" con un estilo más intenso. |
| RF-43 | Los anuncios no tapan el centro de la mira más de lo necesario y se desvanecen. |

### 4.6 Cómo jugar

| ID | Requisito |
|---|---|
| RF-50 | Es una pantalla con **secciones navegables** (pestañas o páginas). Cada sección tiene un título, 2 a 4 puntos breves y una ilustración o captura. |
| RF-51 | Secciones: **Objetivo** (victoria y derrota), **Animales y comida** (barras de vida y alimento, alimentar), **Recintos** (integridad, destructores, escape, cansancio y recaptura con comida), **Armas** (escopeta, munición, cajas de munición que brillan en el mapa, hacha ilimitada, no usar armas mientras cargas comida), **Oleadas** (3 oleadas, descanso, zombis vivos que pasan a la siguiente, horda al morir un animal), **Monedas** (recompensas y penalizaciones) y **HUD** (captura del HUD anotada con cada elemento). |
| RF-52 | Se puede abrir desde el menú principal y desde la pausa. |

### 4.7 Controles

| ID | Requisito |
|---|---|
| RF-60 | La pantalla **Controles** muestra todas las acciones de juego y menú en una tabla con columnas de teclado/mouse y gamepad; cada fila incluye descripción e iconos (sección 7). |
| RF-61 | Se puede abrir la pantalla **Controles** desde el menú principal y desde el menú de pausa. |
| RF-62 | La pantalla es informativa: muestra las asignaciones actuales, pero no permite reasignar teclas ni botones. La reasignación queda fuera de alcance por ahora. |
| RF-63 | Controles se presenta como una ventana emergente centrada, compacta y claramente separada del fondo; no ocupa toda la pantalla. Debe incluir todas las acciones vigentes en una tabla desplazable, y un botón visible **Salir** que vuelve a la pantalla anterior. Esc y el botón de volver del gamepad también la cierran. |
| RF-64 | Los iconos de controles en todo el juego (HUD, consejos, menús) se actualizan con la asignación actual y el último dispositivo usado (teclado, Xbox o PlayStation). |

### 4.8 Configuración

| ID | Requisito |
|---|---|
| RF-70 | **Gráficos:** modo de ventana (ventana / pantalla completa / sin bordes), resolución, VSync, límite de FPS (30 / 60 / 120 / sin límite), calidad de sombras (baja / media / alta), escala de renderizado (50–100 %), antialiasing (apagado / FXAA / MSAA 2x) y brillo. |
| RF-71 | **Audio:** volumen general, música, efectos, interfaz; silenciar al perder el foco de la ventana. |
| RF-72 | **Controles:** sensibilidad del mouse, sensibilidad del stick, invertir eje Y (por separado para mouse y stick), campo de visión (FOV, 70–100°), vibración del control (sí/no) y acceso a la pantalla informativa de controles. |
| RF-73 | **Gameplay y accesibilidad:** consejos activados (sí/no), reiniciar consejos, tamaño de los textos de la interfaz (100 / 125 / 150 %), intensidad del movimiento de cámara al disparar (retroceso, 0–100 %), mira visible (sí/no) e idioma (**Español** por defecto / English). |
| RF-74 | Los cambios se aplican **al momento**. Los cambios de pantalla (resolución o modo de ventana) piden confirmación y se revierten solos a los 10 s si no se confirman. |
| RF-75 | La configuración se **guarda** en el equipo del jugador y se carga al abrir el juego. Hay un botón **Restaurar valores por defecto** por pestaña. |

### 4.9 Menú de pausa

Este requisito amplía el RF-107 de la spec 001.

| ID | Requisito |
|---|---|
| RF-80 | Se abre con Esc o Start. Pausa el juego, incluidos los temporizadores de hambre y de oleada, y libera el mouse. |
| RF-81 | Opciones: **Continuar**, **Cómo jugar**, **Controles**, **Configuración**, **Reiniciar** (con confirmación) y **Salir al menú** (con confirmación). |
| RF-82 | La pausa muestra un **resumen rápido del estado**: oleada, tiempo, saldo de monedas y estado de cada animal. |
| RF-83 | Si el control se desconecta durante la partida, el juego se pausa solo. |

### 4.10 Créditos

| ID | Requisito |
|---|---|
| RF-90 | La pantalla **Créditos** lista al equipo y **todos los assets externos** con autor y licencia, tomados del registro de `docs/assets.md`. |

### 4.11 Requisitos generales de interfaz

| ID | Requisito |
|---|---|
| RF-100 | Todos los menús se pueden navegar con **mouse, teclado (flechas/Enter/Esc) y gamepad** (stick o cruceta, A/Cruz para aceptar, B/Círculo para volver). Siempre hay un elemento con foco visible. |
| RF-101 | Toda la interfaz comparte un **mismo tema visual**: tipografía, colores (estilo zoológico abandonado) y sonidos de navegación y confirmación. |
| RF-102 | Los textos que ve el jugador están en **español** por defecto, con opción de cambiar a **inglés** (RF-73). Se gestionan con el sistema de traducciones de Godot: ningún texto visible va escrito directamente en el código. |
| RF-103 | La interfaz se adapta a resoluciones de 1280×720 a 3840×2160 y a relaciones de aspecto de 16:9 y 16:10. |

## 5. Valores configurables

| Parámetro | Valor inicial |
|---|---|
| Cuenta regresiva antes de la oleada 1 | 5 s |
| Duración de un consejo contextual | 6 s |
| Duración del anuncio de oleada | 3 s |
| Tiempo para confirmar un cambio de pantalla | 10 s |
| Sensibilidad del mouse / stick por defecto | 1.0 / 1.0 |
| FOV por defecto | 80° |

## 6. Contenido de instrucciones

Los textos van en el archivo de traducción, en español (principal) y en inglés.

### 6.1 Consejos contextuales (primera vez)

| ID | Disparador | Mensaje | Prioridad |
|---|---|---|---|
| TIP-01 | Inicio de la primera partida, después del briefing | "Muévete con [WASD], mira con el [mouse]." | Normal |
| TIP-02 | Primera vez cerca de una caja de alimento | "Recoge la comida con [E]. Mientras la cargas no puedes usar armas." | Normal |
| TIP-03 | Primera vez cargando una caja | "Lleva la comida al comedero de un animal y pulsa [E]." | Normal |
| TIP-04 | La barra de alimento de un animal baja del 50 % | "La {jirafa} tiene hambre. Cuando su barra de alimento se vacía, empieza a perder vida." | Alta |
| TIP-05 | Primer zombi visible | "Dispara con [clic]. Recarga con [R]." | Normal |
| TIP-06 | Primera vez sin munición en el cargador y sin reserva | "¡Sin munición! Cambia al hacha con [Q] o busca cajas que brillan en el mapa." | Alta |
| TIP-07 | Primera caja de munición del mapa visible | "Las luces de colores marcan munición. Explora para encontrarla." | Normal |
| TIP-08 | Primer recinto bajo ataque | "¡Los zombis atacan el recinto del {elefante}! Si lo destruyen, el animal escapará." | Alta |
| TIP-09 | Primer animal escapado | "El {elefante} escapó. Carga comida cerca de él para que te siga a un refugio libre." | Alta |
| TIP-10 | Primer animal siguiendo al jugador | "Llévalo a un refugio marcado con [icono]. No te alejes demasiado." | Normal |
| TIP-11 | Primera muerte del jugador | "Reapareces en la cafetería. Los animales siguen necesitándote." | Normal |
| TIP-12 | Primer descanso entre oleadas | "Aprovecha el descanso para alimentar a los animales y buscar munición." | Normal |
| TIP-13 | Primer animal muerto | "El {animal} se convirtió en zombi. Protege al que queda." | Alta |

### 6.2 Consejos generales (pantalla de carga y descansos)

- Los zombis destructores van directo a los recintos: dispárales antes de que lleguen.
- El hacha nunca se queda sin munición, pero te obliga a acercarte.
- Un animal cansado no puede huir: llega rápido con comida.
- Los zombis que sobreviven a una oleada siguen en la siguiente.
- Alimentar a un animal mantiene su vida y su saciedad; cada alimentación y cada zombi eliminado dan 5 monedas.
- Si mueres, pierdes la comida que cargabas.

## 7. Controles por defecto

| Acción | Teclado/Mouse | Gamepad (Xbox / PlayStation) | Descripción en pantalla |
|---|---|---|---|
| Moverse | W A S D | Stick izquierdo | Moverse |
| Mirar | Mouse | Stick derecho | Mirar |
| Correr (mantener) | Shift izquierdo | L3 | Correr |
| Saltar | Espacio | B / Círculo | Saltar |
| Disparar / golpear | Clic izquierdo | RT / R2 | Disparar / Golpear |
| Recargar | R | X / Cuadrado | Recargar |
| Interactuar (recoger, alimentar) | E | A / Cruz | Interactuar |
| Cambiar arma | Q / rueda del mouse | Y / Triángulo | Cambiar arma |
| Escopeta | 1 | — | Escopeta |
| Hacha | 2 | — | Hacha |
| Pausa | Esc | Start / Options | Pausa |
| Menú: aceptar | Enter / clic | A / Cruz | Aceptar |
| Menú: volver | Esc | B / Círculo | Volver |
| Menú: cambiar pestaña | Q / E | LB / RB (L1 / R1) | Pestaña anterior / siguiente |

## 8. Criterios de aceptación

- **CA-01:** Desde el título se llega a una partida, y de ahí a la pausa y de vuelta al menú, usando **solo el gamepad**.
- **CA-02:** El tutorial aparece al iniciar la partida, se puede cerrar y da paso a la cuenta regresiva y la oleada 1.
- **CA-03:** Cada consejo de la sección 6.1 aparece una sola vez, en su evento. Al desactivar los consejos no aparece ninguno. Al reiniciarlos vuelven a aparecer.
- **CA-04:** Los anuncios de las oleadas 1, 2 y 3 (final) y del descanso aparecen con su texto y su cuenta regresiva.
- **CA-05:** La pantalla Controles se abre desde el menú principal y la pausa y muestra todas las acciones, teclas y botones actualmente usados. No ofrece controles de reasignación.
- **CA-06:** Los cambios de gráficos, audio y ajustes de sensibilidad se aplican al momento y se conservan al reiniciar el juego.
- **CA-07:** La pausa detiene los temporizadores de hambre y de oleada.
- **CA-08:** **Cómo jugar** cubre todas las mecánicas de la spec 001: objetivo, animales, recintos, armas, oleadas, puntuación y HUD.
- **CA-09:** Los créditos coinciden con el registro de licencias de `docs/assets.md`.
- **CA-10:** Toda la interfaz se lee correctamente a 1280×720 y a 4K.
- **CA-11:** Desde menú principal y pausa, Controles aparece como ventana emergente compacta, muestra todas las acciones (con desplazamiento si hace falta) y vuelve a la pantalla anterior mediante el botón **Salir**, Esc o el botón de volver del gamepad.
- **CA-12:** Al pulsar Jugar aparece una ventana que explica que hay una jirafa y un elefante, que la comida está en cajas por el mapa y que hay que alimentarlos y protegerlos de zombis y hambre. El juego permanece pausado; al pulsar **Comenzar** desaparece el tutorial y empieza la secuencia previa a las oleadas.

## 9. Fuera de alcance

- Tutorial guiado en un nivel aparte. El tutorial breve de una pantalla está incluido; el recorrido guiado queda fuera de alcance.
- Perfiles de jugador múltiples y logros.
- Más idiomas además de español e inglés.
- Subtítulos de voces (el juego no tiene diálogos).

## 10. Supuestos y preguntas abiertas

| ID | Tema | Supuesto por defecto | Estado |
|---|---|---|---|
| D-01 | Idioma de los textos del juego | **Español** por defecto, con opción de inglés | ✅ Confirmado (2026-11-17) |
| D-02 | Tutorial | Ventana breve al comenzar + consejos contextuales, sin nivel de tutorial aparte | ✅ Confirmado (2026-11-20) |
| S-03 | Fondo del menú | Recorrido lento de cámara por el mapa real | Supuesto |
