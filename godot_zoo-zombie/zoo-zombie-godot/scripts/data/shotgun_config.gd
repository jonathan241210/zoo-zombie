class_name ShotgunConfig
extends Resource
## Shotgun tuning (spec 001 §6 Escopeta).
## Values in the matching .tres under res://config/ are the source of truth.

@export var magazine_size: int = 6
@export var starting_reserve: int = 24
@export var max_reserve: int = 48
@export var pellets_per_shot: int = 8
@export var damage_per_pellet: float = 12.0
@export var spread_degrees: float = 6.0
## Meters.
@export var max_range: float = 30.0
## Seconds between shots.
@export var fire_interval: float = 0.8
## Seconds.
@export var reload_time: float = 2.5
## HUD warns at or below this reserve.
@export var low_reserve_threshold: int = 6
## Camera kick per shot.
@export var camera_recoil_degrees: float = 3.0
