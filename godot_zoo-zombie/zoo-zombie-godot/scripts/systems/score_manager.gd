class_name ScoreManager
extends Node
## Owns the match coin balance and applies configured rewards and penalties.

@export var config: ScoreConfig

var coins: int = 0


func _ready() -> void:
	assert(config != null, "ScoreManager needs a ScoreConfig")
	EventBus.zombie_killed.connect(_on_zombie_killed)
	EventBus.coins_earned.connect(_change_coins)
	EventBus.ammo_collected.connect(_on_ammo_collected)
	EventBus.animal_recaptured.connect(_on_animal_recaptured)
	EventBus.player_died.connect(_on_player_died)
	EventBus.animal_died.connect(_on_animal_died)
	EventBus.score_changed.emit(coins)


func _on_zombie_killed(_zombie: Node3D) -> void:
	_change_coins(config.zombie_kill)


func _on_animal_recaptured(_animal_id: StringName, _enclosure: Node3D) -> void:
	_change_coins(config.recapture)


func _on_player_died() -> void:
	_change_coins(-config.player_death_penalty)


func _on_animal_died(_animal_id: StringName, _position: Vector3) -> void:
	_change_coins(-config.animal_death_penalty)


func _on_ammo_collected(_amount: int) -> void:
	_change_coins(config.ammo_pickup)


func _change_coins(amount: int) -> void:
	coins = maxi(coins + amount, 0)
	EventBus.score_changed.emit(coins)
