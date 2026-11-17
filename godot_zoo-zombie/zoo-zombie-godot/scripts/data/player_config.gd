class_name PlayerConfig
extends Resource
## First-person player tuning (spec 001 §6 Jugador).
## Values in the matching .tres under res://config/ are the source of truth.

## Maximum health points.
@export var max_health: float = 100.0
## m/s.
@export var walk_speed: float = 4.5
## m/s.
@export var sprint_speed: float = 7.0
## m/s while carrying a food crate.
@export var carry_speed: float = 3.2
## How fast velocity reaches the target speed (1/s).
@export var acceleration: float = 12.0
## How fast the player stops (1/s).
@export var deceleration: float = 14.0
## Camera height above the feet (m).
@export var eye_height: float = 1.65
## Radians per mouse pixel.
@export var mouse_sensitivity: float = 0.0025
## Radians per second at full stick deflection.
@export var stick_sensitivity: float = 3.0
## Right stick deadzone (0-1).
@export var stick_deadzone: float = 0.15
## Max look up/down angle.
@export var pitch_limit_degrees: float = 85.0
## Camera field of view (degrees).
@export var fov: float = 80.0
## Max distance to interact (m).
@export var interact_distance: float = 2.5
## Seconds to swap shotgun/axe.
@export var weapon_switch_time: float = 0.4
## Seconds before respawning after death.
@export var respawn_delay: float = 3.0
