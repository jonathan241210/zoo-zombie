# Assets del juego

Inventario de modelos 3D y audio: qué hay, qué se usa, qué falta y cómo se resuelve.

## Requisitos para modelos descargados

- **Formato:** GLB preferido. FBX solo si no hay otra opción: se convierte a GLB en Blender.
- **Prioridad:** modelos que **ya traen rig y animaciones**.
- **Estilo:** low-poly o estilizado, para combinar con el mapa.
- **Licencia:** CC0, CC-BY o una que permita uso en videojuegos. Anota autor y fuente en el registro de abajo.
- **Dónde guardarlos:** `assets/models/` (la descarga original, sin modificar). Hoy la carpeta se llama `assets/modelos/`; se renombra en la tarea T-003.

## Inventario actual

| Archivo | Rig | Animaciones | Rol en el juego | Falta |
|---|---|---|---|---|
| `girafa_animada.glb` | ✅ | idle, walk, run, eat, attack | **Jirafa** | `weak`, `death` (se hacen con código) |
| `elefante_animado.glb` | ✅ | idle, walk, run, eat, attack | **Elefante** | `weak`, `death` (se hacen con código) |
| `animation_zombie_2.glb` | ✅ | idle, walk, run, attack, damage, death y más | **Zombi** | — |
| `brazo_escopeta.glb` | ✅ | disparo, sacar arma, sostener caja, agarrar y otras | **Brazos en primera persona** | `reload` (se hace con código) |
| `escopeta.glb` | ❌ | — | Prop o pickup de la escopeta | — |
| `hacha.glb` | ❌ | — | **Hacha** (arma secundaria) | Golpe: se reutiliza `E_Martillo` de los brazos |
| `brazos_ametralladora.glb` | ✅ | draw, fire, reload, holster | Reservado para un arma futura | — |
| `zombie_dog_animation.glb` | ✅ | idle, walk, run, attack, hit, jump | Reservado para un enemigo futuro | — |
| `mad_zombie.glb` | ❌ | — | Sin uso (lo reemplaza `animation_zombie_2`) | — |
| `low_poly_animals.glb` | ❌ | — | Sin uso (solo referencia) | — |

## Lo que se genera con código

| Modelo / animación | Script | Motivo |
|---|---|---|
| Caja de alimento | `blender_zoo-zombie/scripts/models/food_crate.py` | Geometría simple |
| Caja de munición | `blender_zoo-zombie/scripts/models/ammo_box.py` | Geometría simple |
| Comedero de jirafa (elevado, con poste) | `blender_zoo-zombie/scripts/models/giraffe_feeder.py` | Diseño específico del juego |
| Comedero de elefante (bajo) | `blender_zoo-zombie/scripts/models/elephant_feeder.py` | Diseño específico del juego |
| `death` de la jirafa y del elefante | `blender_zoo-zombie/scripts/prepare/prepare_giraffe.py` y `prepare_elephant.py` | No viene en la descarga |
| `weak` de la jirafa y del elefante | En Godot (velocidad reducida + cabeza baja) | No viene en la descarga |
| `reload` de la escopeta | `blender_zoo-zombie/scripts/prepare/prepare_fp_arms.py` | No viene en la descarga |

## Opcional (para más adelante)

| Modelo | Términos de búsqueda |
|---|---|
| Más animales con rig y animaciones | `low poly <animal> rigged animated` |
| Elementos ambientales | `low poly barricade`, `abandoned car low poly`, `blood decal` |

## Audio necesario

| Sonido | Términos sugeridos |
|---|---|
| Disparo y recarga de escopeta (pump) | `shotgun shot`, `shotgun pump reload` |
| Zombi: gemido, ataque y muerte | `zombie groan`, `zombie attack` |
| Jirafa y elefante: comer, quejido y estampida | `elephant trumpet`, `animal eating`, `hooves running` |
| Recinto golpeado y destruido | `metal fence hit`, `fence break` |
| Recoger caja / munición | `pickup`, `item pickup` |
| Música: ambiente y oleada | `horror ambient loop`, `action zombie music` |
| UI: inicio de oleada, alerta, victoria y derrota | `wave start horn`, `alarm`, `victory jingle` |

Fuentes con licencias libres: freesound.org (revisa la licencia de cada sonido), kenney.nl (CC0), opengameart.org.

## Registro de licencias

| Archivo | Fuente / URL | Autor | Licencia |
|---|---|---|---|
| `girafa_animada.glb` | Sketchfab | _pendiente_ | _pendiente_ |
| `elefante_animado.glb` | Sketchfab | _pendiente_ | _pendiente_ |
| `animation_zombie_2.glb` | Sketchfab | _pendiente_ | _pendiente_ |
| `brazo_escopeta.glb` | Sketchfab | _pendiente_ | _pendiente_ |
| `escopeta.glb` | Sketchfab | _pendiente_ | _pendiente_ |
| `hacha.glb` | Sketchfab | _pendiente_ | _pendiente_ |
| `brazos_ametralladora.glb` | Sketchfab | _pendiente_ | _pendiente_ |
| `zombie_dog_animation.glb` | Sketchfab | _pendiente_ | _pendiente_ |
