# AGENTS.md — Guía para agentes de IA y colaboradores

Este archivo define **cómo se trabaja** en el repositorio Zoo Zombie. Aplica a cualquier agente de IA (Claude Code, Codex, Cursor, Copilot, etc.) y a cualquier persona del equipo.

Antes de hacer cualquier cambio, lee en este orden:

1. [`docs/constitution.md`](docs/constitution.md): principios del proyecto. No se negocian.
2. [`docs/specs/`](docs/specs/), [`docs/plans/`](docs/plans/) y [`docs/tasks/`](docs/tasks/): especificación, plan y tareas de la funcionalidad en curso.
3. [`docs/decisions/`](docs/decisions/): decisiones técnicas (ADR) ya tomadas.
4. [`docs/setup/mcp.md`](docs/setup/mcp.md): cómo conectar Blender y Godot por MCP.

---

## 1. Idioma

| Qué | Idioma |
|---|---|
| Mensajes de commit | **Español** |
| Documentación SDD y del proyecto (`docs/`, `README.md`, `AGENTS.md`) | **Español** |
| Código (GDScript, Python para Blender, shaders) | **Inglés** |
| Comentarios y docstrings dentro del código | **Inglés** |
| Nombres de archivos, carpetas, escenas, nodos, recursos, señales, acciones de input, objetos y materiales nuevos en Blender | **Inglés** |
| Textos que ve el jugador (HUD, menús, consejos) | **Español** como idioma principal, con opción de **inglés**. Se gestionan con el sistema de traducciones de Godot (CSV); las **claves** de traducción van en inglés |

Esta regla solo cambia si el usuario lo pide **explícitamente**.

> Los nombres en español que ya existen en el mapa de Blender (`REC_ESTANQUE_1`, `04_VEGETACION`, etc.) se respetan. No se renombran sin pedirlo.

## 2. Flujo de trabajo: Spec-Driven Development (SDD)

Cada funcionalidad recorre estas etapas **en orden**:

1. **Spec** (`docs/specs/NNN-nombre.md`): *qué* se construye y *por qué*. Incluye historias de usuario, requisitos funcionales con ID (`RF-xx`), valores configurables y criterios de aceptación. No describe la implementación.
2. **Plan** (`docs/plans/NNN-nombre.md`): *cómo* se construye. Arquitectura, escenas, scripts, recursos, datos y decisiones técnicas.
3. **Tasks** (`docs/tasks/NNN-nombre.md`): lista de tareas pequeñas, ordenadas y verificables, con ID (`T-xxx`). Cada tarea indica qué requisito cubre.
4. **Implementación**: una tarea a la vez, marcándola como hecha en el archivo de tasks.
5. **Verificación**: se prueba contra los criterios de aceptación de la spec antes de pasar a la siguiente fase.

Reglas:

- Cada funcionalidad tiene **el mismo nombre de archivo** en las tres carpetas. Ejemplo: `docs/specs/001-zoo-survival.md`, `docs/plans/001-zoo-survival.md` y `docs/tasks/001-zoo-survival.md`.
- Las funcionalidades nuevas usan el siguiente número: `002-...`, `003-...`.
- **No se implementa nada que no esté en una spec aprobada.** Si surge algo nuevo, primero se actualiza la spec.
- **No se empieza una fase sin aprobación del usuario.**
- Cuando cambie el alcance, se actualizan spec, plan y tasks **en el mismo cambio**.
- Las decisiones técnicas importantes se registran como ADR en `docs/decisions/`.

## 3. Preguntas al usuario

- Si algo no está claro, o falta información necesaria para implementar, **pregunta antes de suponer**.
- **Máximo 5 preguntas por ronda.** Prioriza las que bloquean el trabajo.
- Cada pregunta propone una opción recomendada y explica qué cambia según la respuesta.
- Lo que no bloquee el trabajo se registra en la spec como **supuesto** (sección "Supuestos y preguntas abiertas"), con su valor por defecto, para que el usuario lo valide después.

## 4. Commits

- Mensajes en **español**. Describen **la funcionalidad o el cambio que se hizo**, nada más.
- **No** se agrega `Co-Authored-By`, `Generated with`, firmas, emojis ni ninguna mención de herramientas o agentes de IA.
- Un commit por funcionalidad o cambio coherente. No se mezclan cambios no relacionados.
- Formato: `tipo(ámbito): descripción en imperativo`
  - Tipos: `feat`, `fix`, `docs`, `refactor`, `assets`, `test`, `chore`, `perf`.
  - Ejemplos:
    - `feat(zombis): agrega persecución del jugador con NavigationAgent3D`
    - `assets(jirafa): agrega modelo low-poly con animaciones de reposo y caminata`
    - `docs(spec): define sistema de oleadas y valores configurables`
- El cuerpo del commit es opcional. Si lo hay, explica el *por qué* en viñetas breves.
- Los agentes de IA **no hacen commit ni push** a menos que el usuario lo pida.

## 5. Reglas de desarrollo

- **Analiza antes de modificar.** Revisa las escenas, scripts y recursos existentes. No inventes archivos, clases o sistemas sin confirmar que existen o que hacen falta.
- **Respeta la arquitectura** definida en el plan vigente (`docs/plans/`). Si hace falta cambiarla, primero explica por qué y espera aprobación.
- **No dupliques funcionalidades.** Reutiliza componentes (`HealthComponent`, `Interactable`, etc.).
- **Todo valor de diseño es configurable**: vida, daño, puntos, tiempos, cantidades y velocidades viven en recursos `.tres` (`Resource` personalizados), no escritos a mano dentro del código.
- **Implementación progresiva**: una fase a la vez, y se prueba antes de continuar.
- Los scripts de Blender van uno por modelo, reutilizando utilidades comunes. Nunca un script gigante.
- No borres ni sobrescribas archivos `.blend`, escenas ni assets del usuario sin confirmarlo.

## 6. Estructura del repositorio

```
zoozombie/
├── AGENTS.md                  ← este archivo
├── README.md
├── blender_zoo-zombie/        ← archivos .blend fuente + scripts Python de Blender
├── godot_zoo-zombie/
│   └── zoo-zombie-godot/      ← proyecto Godot (project.godot)
├── assets/                    ← descargas originales (fuente), antes de importarlas al juego
└── docs/
    ├── constitution.md        ← principios del proyecto
    ├── assets.md              ← lista de modelos/audio necesarios y sus licencias
    ├── decisions/             ← ADR (decisiones técnicas)
    ├── setup/                 ← guías de configuración (MCP, herramientas)
    ├── specs/                 ← SDD: qué se construye (NNN-nombre.md)
    ├── plans/                 ← SDD: cómo se construye (NNN-nombre.md)
    └── tasks/                 ← SDD: tareas de implementación (NNN-nombre.md)
```

## 7. Herramientas

- **Godot 4.7** (Forward+, Jolt Physics) y GDScript con tipado estático.
- **Blender 5.3** para modelado y scripts procedurales (`bpy`).
- **MCP**: Blender (`mcp-for-blender`) y Godot (`@coding-solo/godot-mcp`). Ver [`docs/setup/mcp.md`](docs/setup/mcp.md).
- Formato de intercambio de modelos: **GLB** (glTF 2.0 binario).
