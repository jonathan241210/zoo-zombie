extends GutTest
## Destructible enclosures, escape, lure, recapture and zombification in the real game
## scene (spec 001 phase 7: RF-30 to RF-49, RF-60 to RF-62, CA-04 to CA-07).

const GAME := preload("res://scenes/main/game.tscn")

var game: Node3D
var player: PlayerController
var registry: EnclosureRegistry
var spawner: ZombieSpawner


func before_each() -> void:
	game = GAME.instantiate()
	(game.get_node("ZombieSpawner") as ZombieSpawner).test_zombie_count = 0
	add_child_autofree(game)
	await wait_physics_frames(10)
	player = game.get_node("Player")
	player.input_enabled = false
	registry = game.get_node("EnclosureRegistry")
	spawner = game.get_node("ZombieSpawner")


func _animal(animal_id: StringName) -> Animal:
	for node in game.get_node("ZooLevel").get_children():
		if node is Animal and node.config.animal_id == animal_id:
			return node
	return null


func _destroy_home(animal: Animal) -> Enclosure:
	var home := animal.enclosure
	home.health.take_damage(home.health.max_health)
	return home


func _zombie_count() -> int:
	return get_tree().get_nodes_in_group(&"zombies").size()


func test_occupied_enclosure_has_integrity() -> void:
	var home := _animal(&"elephant").enclosure
	assert_eq(home.health.max_health, registry.config.max_integrity, "RF-30")
	assert_true(home.can_be_attacked())
	assert_eq(home.get_attack_points().size(), registry.config.attack_point_count)
	for point in home.get_attack_points():
		assert_gt(home.distance_to_outline(point), 0.5, "attack points are outside the fence")


func test_destroyed_enclosure_releases_the_animal() -> void:
	# RF-32, RF-33, CA-04.
	var elephant := _animal(&"elephant")
	watch_signals(EventBus)
	var home := _destroy_home(elephant)
	assert_true(home.is_destroyed)
	assert_signal_emitted(EventBus, "enclosure_destroyed")
	assert_signal_emitted_with_parameters(EventBus, "animal_escaped", [&"elephant"])
	assert_true(elephant.is_escaped())
	assert_false(elephant.can_be_fed(), "RF-26")
	assert_false(elephant.feeder.visible, "feeder unusable until it has a new enclosure")
	assert_false(home.can_receive_animal(), "destroyed for the rest of the match")
	await wait_seconds(3.0)
	assert_gt(home.distance_to_outline(elephant.global_position), 0.0, "it ran out through the broken fence")
	home.health.reset(1.0)
	assert_true(home.is_destroyed, "cannot be repaired")


func test_escaped_animal_flees_and_gets_tired() -> void:
	# RF-40 to RF-42, CA-05.
	var elephant := _animal(&"elephant")
	_destroy_home(elephant)
	await wait_seconds(2.5)
	elephant.stamina = Stamina.new(10.0, 10.0, 1.0, 0.5)
	var zombie := spawner.spawn_at(elephant.global_position + Vector3(3.0, 0.0, 0.0), true)
	zombie.config = zombie.config.duplicate()
	zombie.config.walk_speed = 0.0
	zombie.config.run_speed = 0.0
	zombie.config.damage_to_animal = 0.0
	var start := elephant.global_position.distance_to(zombie.global_position)
	await wait_seconds(0.5)
	assert_eq(elephant.state, Animal.State.FLEEING, "RF-40")
	await wait_seconds(1.0)
	assert_true(elephant.stamina.is_tired)
	assert_eq(elephant.state, Animal.State.TIRED, "RF-42")
	assert_gt(elephant.global_position.distance_to(zombie.global_position), start, "it got away")


func test_zombie_attacks_escaped_animal() -> void:
	# RF-43, RF-62.
	var elephant := _animal(&"elephant")
	_destroy_home(elephant)
	await wait_seconds(2.5)
	elephant.stamina = Stamina.new(0.01, 1.0, 0.0, 1.0)
	var zombie := spawner.spawn_at(elephant.global_position + Vector3(1.5, 0.0, 0.0), true)
	zombie.config = zombie.config.duplicate()
	zombie.config.attack_hit_delay = 0.05
	await wait_seconds(1.5)
	assert_eq(zombie.target, elephant, "any zombie goes for an escaped animal")
	assert_lt(elephant.health.current_health, elephant.health.max_health)


func test_breaker_hits_occupied_enclosure_then_hunts_player_when_hurt() -> void:
	# RF-60, RF-61.
	var home := _animal(&"elephant").enclosure
	var zombie := spawner.spawn_at(home.nearest_attack_point(home.global_position + Vector3(30, 0, 0)), true,
		Zombie.Role.BREAKER)
	zombie.config = zombie.config.duplicate()
	zombie.config.attack_hit_delay = 0.05
	await wait_seconds(1.5)
	assert_eq(zombie.target, home)
	assert_lt(home.health.current_health, home.health.max_health, "the fence takes damage")
	zombie.health.take_damage(1.0, player)
	await wait_seconds(0.8)
	assert_true(zombie.aggro_player)
	assert_eq(zombie.target, player)


func test_lure_and_recapture_in_a_free_refuge() -> void:
	# RF-44, RF-45, CA-06.
	var elephant := _animal(&"elephant")
	_destroy_home(elephant)
	await wait_seconds(2.5)
	var refuge := registry.get_enclosure("REC_RECINTO_NORTE_CENTRAL")
	assert_true(refuge.can_receive_animal())
	# Player with food next to the elephant: it follows.
	var carry: PlayerCarry = player.get_node("PlayerCarry")
	carry.pick_up()
	player.global_position = elephant.global_position + Vector3(2.0, 0.0, 0.0)
	await wait_seconds(0.5)
	assert_eq(elephant.state, Animal.State.FOLLOWING, "RF-44")
	# Walking away beyond the maximum radius breaks the lure.
	player.global_position = elephant.global_position + Vector3(elephant.config.follow_max_radius + 4.0, 0.0, 0.0)
	await wait_seconds(0.5)
	assert_ne(elephant.state, Animal.State.FOLLOWING)
	# Lead it to the refuge fence.
	var gate := refuge.nearest_attack_point(refuge.feeder_anchor.origin)
	elephant.global_position = gate
	player.global_position = gate + (gate - refuge.global_position).normalized() * 2.0
	watch_signals(EventBus)
	await wait_seconds(0.8)
	assert_signal_emitted(EventBus, "animal_recaptured")
	assert_eq(elephant.enclosure, refuge)
	assert_eq(refuge.occupant, elephant, "RF-35: one animal per enclosure")
	assert_true(refuge.is_inside(elephant.global_position))
	assert_true(elephant.feeder.visible)
	assert_almost_eq(elephant.feeder.global_position.distance_to(refuge.feeder_anchor.origin), 0.0, 0.05,
		"its feeder moved to the refuge")
	assert_true(elephant.feed(), "can be fed right away")
	assert_true(refuge.can_be_attacked(), "an occupied refuge is a normal enclosure")


func test_dead_animal_turns_into_a_horde() -> void:
	# RF-47, CA-07.
	var giraffe := _animal(&"giraffe")
	var before := _zombie_count()
	giraffe.health.take_damage(giraffe.health.max_health)
	await wait_physics_frames(2)
	assert_eq(_zombie_count(), before + giraffe.config.death_horde_size)
	assert_eq(GameManager.state, GameManager.GameState.PLAYING, "the match goes on")


func test_defeat_when_both_animals_die() -> void:
	# RF-49, CA-07.
	watch_signals(EventBus)
	for animal_id: StringName in [&"giraffe", &"elephant"]:
		var animal := _animal(animal_id)
		animal.health.take_damage(animal.health.max_health)
	assert_signal_emitted(EventBus, "game_lost")
	assert_eq(GameManager.state, GameManager.GameState.LOST)
