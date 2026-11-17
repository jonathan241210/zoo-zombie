class_name WaveConfig
extends Resource
## One wave definition (spec 001 §6 Oleadas).
## Values in the matching .tres under res://config/ are the source of truth.

## Seconds.
@export var duration: float = 120.0
@export var total_zombies: int = 10
## Seconds.
@export var spawn_interval: float = 8.0
@export var max_alive: int = 6
## 0-1 share of breakers.
@export var breaker_ratio: float = 0.2
@export var speed_multiplier: float = 1.0
@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
