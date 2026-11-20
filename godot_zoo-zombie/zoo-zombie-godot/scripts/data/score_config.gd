class_name ScoreConfig
extends Resource
## Coin rewards and penalties (spec 001 §6 Monedas). Feeding rewards live in AnimalConfig.
## Values in the matching .tres under res://config/ are the source of truth.

@export var zombie_kill: int = 5
@export var recapture: int = 200
@export var ammo_pickup: int = 0
@export var player_death_penalty: int = 100
@export var animal_death_penalty: int = 300
