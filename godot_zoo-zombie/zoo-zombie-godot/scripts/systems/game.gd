extends Node3D
## Root of a match: wires the level, player, enclosures, animals, food and ammo crates, then
## starts the match. Handles the player's death and respawn at the cafeteria (RF-80 to
## RF-83). Waves, score and the full HUD are added in later phases.

## Animals spawned at the start, each into the home enclosure named in its config.
@export var animal_scenes: Array[PackedScene] = []

@onready var level: ZooLevel = $ZooLevel
@onready var player: PlayerController = $Player
@onready var enclosures: EnclosureRegistry = $EnclosureRegistry
@onready var food_crates: FoodCrateDirector = $FoodCrateDirector
@onready var ammo_crates: AmmoSpawnDirector = $AmmoSpawnDirector
@onready var zombies: ZombieSpawner = $ZombieSpawner

var _horde_sizes: Dictionary = {}  # animal_id -> zombies in its zombification horde


func _ready() -> void:
	player.respawn_at(level.player_spawn.global_transform)
	GameManager.start_match()
	var animals: Array[Animal] = []
	var homes := PackedStringArray()
	for scene in animal_scenes:
		var animal := scene.instantiate() as Animal
		animals.append(animal)
		homes.append(animal.config.home_enclosure)
	enclosures.setup(level, homes)
	for animal in animals:
		level.add_child(animal)
		enclosures.assign(animal, enclosures.get_enclosure(animal.config.home_enclosure))
	food_crates.setup(level.get_food_crate_spawns())
	# Wired here: a NodePath from player.tscn to a node outside it cannot resolve.
	(player.get_node("PlayerCarry") as PlayerCarry).food_crate_director = food_crates
	ammo_crates.setup(level.get_ammo_spawns())
	zombies.setup(level.get_zombie_spawns(), player, enclosures)
	for animal in animals:
		_horde_sizes[animal.config.animal_id] = animal.config.death_horde_size
	EventBus.animal_died.connect(_on_animal_died)
	EventBus.player_died.connect(_on_player_died)


## RF-80 to RF-83: the match goes on; after a delay (paused with the game) the player
## reappears at the cafeteria with full health. The score penalty arrives with the
## ScoreManager (phase 9).
func _on_player_died() -> void:
	await get_tree().create_timer(player.config.respawn_delay, false).timeout
	if not is_inside_tree():
		return
	player.respawn_at(level.player_spawn.global_transform)
	EventBus.player_respawned.emit()


## RF-47: a dead animal turns into an extra horde at its position.
func _on_animal_died(animal_id: StringName, at: Vector3) -> void:
	zombies.spawn_horde(at, int(_horde_sizes.get(animal_id, 0)))
