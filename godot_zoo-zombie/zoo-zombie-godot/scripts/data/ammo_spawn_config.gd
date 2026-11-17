class_name AmmoSpawnConfig
extends Resource
## Map ammo crates (spec 001 §6 Munición en el mapa).
## Values in the matching .tres under res://config/ are the source of truth.

## Crates present at once.
@export var active_count: int = 4
@export var shells_per_crate: int = 6
## Seconds after pickup.
@export var respawn_delay: float = 45.0
## Glow color.
@export var light_color: Color = Color(1.0, 0.75, 0.2, 1.0)
@export var light_energy: float = 1.6
## OmniLight3D range (m).
@export var light_range: float = 5.0
## Seconds per glow pulse.
@export var pulse_period: float = 1.6
