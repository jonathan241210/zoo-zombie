class_name FoodCrateConfig
extends Resource
## Food crate spawning (spec 001 §6 Cajas de alimento).
## Values in the matching .tres under res://config/ are the source of truth.

@export var max_active: int = 5
## Seconds.
@export var respawn_delay: float = 30.0
