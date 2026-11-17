class_name ZombieConfig
extends Resource
## Base zombie tuning before wave multipliers (spec 001 §6 Zombi).
## Values in the matching .tres under res://config/ are the source of truth.

@export var max_health: float = 100.0
@export var walk_speed: float = 2.5
@export var run_speed: float = 4.0
@export var damage_to_player: float = 10.0
@export var damage_to_animal: float = 8.0
@export var damage_to_enclosure: float = 15.0
## Seconds between hits.
@export var attack_interval: float = 1.2
## Meters.
@export var attack_range: float = 1.6
## Meters.
@export var detection_radius: float = 25.0
## Breakers switch to the player inside this radius.
@export var breaker_aggro_radius: float = 6.0
## 0-1.
@export var ammo_drop_chance: float = 0.35
## Shells.
@export var ammo_drop_amount: int = 4
## Seconds before a dropped ammo box disappears.
@export var ammo_drop_lifetime: float = 30.0
## Seconds before the body is removed.
@export var corpse_lifetime: float = 8.0
