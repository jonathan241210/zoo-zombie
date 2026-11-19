extends Node3D
## Root of a match: wires the level, player, enclosures, animals, food and ammo crates, then
## starts the match. Waves, score and the full HUD are added in later phases.

## Animals spawned at the start, each into the home enclosure named in its config.
@export var animal_scenes: Array[PackedScene] = []

@onready var level: ZooLevel = $ZooLevel
@onready var player: PlayerController = $Player
@onready var enclosures: EnclosureRegistry = $EnclosureRegistry
@onready var food_crates: FoodCrateDirector = $FoodCrateDirector
@onready var ammo_crates: AmmoSpawnDirector = $AmmoSpawnDirector


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
