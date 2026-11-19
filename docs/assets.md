# Assets del juego

Inventario de modelos 3D y audio: qué hay, qué se usa, qué falta y cómo se resuelve.

## Requisitos para modelos descargados

- **Formato:** GLB preferido. FBX solo si no hay otra opción: se convierte a GLB en Blender.
- **Prioridad:** modelos que **ya traen rig y animaciones**.
- **Estilo:** low-poly o estilizado, para combinar con el mapa.
- **Licencia:** CC0, CC-BY o una que permita uso en videojuegos. Anota autor y fuente en el registro de abajo.
- **Dónde guardarlos:** `assets/models/` (la descarga original, sin modificar).

## Inventario actual

| Archivo | Rig | Animaciones | Rol en el juego | Falta |
|---|---|---|---|---|
| `girafa_animada.glb` | ✅ | idle, walk, run, eat, attack | **Jirafa** → `animals/giraffe.glb` | ✅ `weak` y `death` agregadas por script |
| `elefante_animado.glb` | ✅ | idle, walk, run, eat, attack | **Elefante** → `animals/elephant.glb` | ✅ `weak` y `death` agregadas por script |
| `animation_zombie_2.glb` | ✅ | idle, walk, run, attack, damage, death y más | **Zombi** → `zombies/zombie.glb` | — |
| `brazo_escopeta.glb` | ✅ | disparo, sacar arma, sostener caja, agarrar y otras | **Brazos en primera persona** (un solo brazo) → `weapons/fp_arms_shotgun.glb` | `reload` (por código en Godot, Fase 5) |
| `escopeta.glb` | ❌ | — | Prop o pickup de la escopeta | — |
| `hacha.glb` | ❌ | — | **Hacha** (arma secundaria) | Golpe procedural por código (`E_Martillo` saca el brazo de la cámara) |
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
| `weak` de la jirafa y del elefante | `blender_zoo-zombie/scripts/prepare/prepare_giraffe.py` y `prepare_elephant.py` | No viene en la descarga |
| `reload` de la escopeta | En Godot por código (Tween), `scripts/weapons/shotgun.gd` | No viene en la descarga |
| Golpe del hacha | En Godot por código (Tween), `scripts/player/view_model.gd` | `E_Martillo` saca el brazo de la cámara |
| Sonidos provisionales: `shotgun_fire`, `axe_swing`, `axe_hit` y `ammo_pickup` (`assets/audio/sfx/` del proyecto Godot) | `tools/generate_sfx.py` (síntesis con la biblioteca estándar de Python, semilla fija) | No había SFX; son obra propia sin licencia de terceros y se pueden reemplazar por grabaciones |

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

**CC-BY 4.0** obliga a dar crédito al autor. Todos estos créditos deben aparecer en la pantalla de Créditos (spec 002, RF-90).

| Archivo | Fuente / URL | Autor | Licencia |
|---|---|---|---|
| `girafa_animada.glb` | [Reticulated Giraffe - Rigged & Animated](https://sketchfab.com/3d-models/reticulated-giraffe-rigged-animated-b8a7cf34d2614b8c93e76d5300f9aaaa) | Animal Animator | CC-BY 4.0 |
| `elefante_animado.glb` | [African Elephant Bull - Rigged & Animated](https://sketchfab.com/3d-models/african-elephant-bull-rigged-animated-436483857ce84c77bd0f6c76fb3d4d2d) | Animal Animator | CC-BY 4.0 |
| `animation_zombie_2.glb` | [animation zombie 2](https://sketchfab.com/3d-models/animation-zombie-2-d85985955acf4b13992eef113634d4fc) | RINONO | CC-BY 4.0 |
| `brazo_escopeta.glb` | [Brazo_Escopeta](https://sketchfab.com/3d-models/brazo-escopeta-c4c6f4784d004236bdc6229624537a2a) | BelBox | CC-BY 4.0 |
| `escopeta.glb` | [Escopeta](https://sketchfab.com/3d-models/escopeta-f25bc5c3a1174d40a809f91c85bfbea2) | nirck25 | CC-BY 4.0 |
| `hacha.glb` | [Hacha](https://sketchfab.com/3d-models/hacha-9425ff48e0d04ba2a467ee59817ad1a2) | LucyFer_705 | CC-BY 4.0 |
| `brazos_ametralladora.glb` | [M4 - FPS Weapon Animations Pack (v.1)](https://sketchfab.com/3d-models/m4-fps-weapon-animations-pack-v1-662fc74dda2646cfb48fc610705768ef) | BarcodeGames | CC-BY 4.0 |
| `zombie_dog_animation.glb` | [Zombie Dog animation](https://sketchfab.com/3d-models/zombie-dog-animation-cfe2c0015d284edd9d826a4e266080e2) | hino | CC-BY 4.0 |
| `mad_zombie.glb` | [Mad Zombie!](https://sketchfab.com/3d-models/mad-zombie-3ae800207d764fcebb16db191ca35eca) | MadGamesmith | CC-BY 4.0 (sin uso) |
| `low_poly_animals.glb` | [Low Poly Animals](https://sketchfab.com/3d-models/low-poly-animals-4e5d0b71c2de49189dfa81476f4ae203) | EdwinRC | CC-BY 4.0 (sin uso) |
| `godot_zoo-zombie/zoo-zombie-godot/assets/ui/glyphs/` (57 iconos de entrada, versión *Double* de 128 px) | [Input Prompts 1.5](https://kenney.nl/assets/input-prompts) | Kenney | CC0 (no requiere crédito; se incluye por cortesía). El paquete completo vive en `assets/kenney_input-prompts_1.5/`, fuera de Git |
