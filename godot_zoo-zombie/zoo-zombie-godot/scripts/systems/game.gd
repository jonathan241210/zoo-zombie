extends Node3D
## Root of a match: wires the level and the player, then starts the match.
## Gameplay managers (waves, score, enclosures) are added here in later phases.

@onready var level: ZooLevel = $ZooLevel
@onready var player: PlayerController = $Player


func _ready() -> void:
	player.respawn_at(level.player_spawn.global_transform)
	GameManager.start_match()
