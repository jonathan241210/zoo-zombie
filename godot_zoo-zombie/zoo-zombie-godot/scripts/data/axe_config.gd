class_name AxeConfig
extends Resource
## Axe tuning (spec 001 §6 Hacha).
## Values in the matching .tres under res://config/ are the source of truth.

@export var damage: float = 40.0
## Meters.
@export var max_range: float = 2.2
@export var arc_degrees: float = 90.0
## Zombies hit per swing.
@export var max_targets: int = 2
## Seconds between swings.
@export var swing_interval: float = 0.9
## Meters pushed back.
@export var knockback: float = 1.0
