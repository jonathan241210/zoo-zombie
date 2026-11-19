extends GutTest
## Hunter zombies and player death in the real game scene (spec 001 phase 6:
## RF-55, RF-63 to RF-68, RF-80 to RF-83, CA-08, CA-11).

const GAME := preload("res://scenes/main/game.tscn")

var game: Node3D
var player: PlayerController
var spawner: ZombieSpawner


func before_each() -> void:
	game = GAME.instantiate()
	(game.get_node("ZombieSpawner") as ZombieSpawner).test_zombie_count = 0
	add_child_autofree(game)
	await wait_physics_frames(10)
	player = game.get_node("Player")
	spawner = game.get_node("ZombieSpawner")
	player.input_enabled = false
	# Open ground in front of the cafeteria.
	player.global_position = Vector3(10.0, 1.6, 9.0)
	await wait_physics_frames(4)


## Zombie with its own copy of the config so a test can change values safely.
func _spawn(offset: Vector3, alerted: bool = true) -> Zombie:
	var zombie := spawner.spawn_at(player.global_position + offset, alerted)
	zombie.config = zombie.config.duplicate()
	zombie.global_position = player.global_position + offset
	return zombie


func test_test_zombies_spawn_at_the_start() -> void:
	var other := GAME.instantiate()
	add_child_autofree(other)
	await wait_physics_frames(5)
	var other_spawner: ZombieSpawner = other.get_node("ZombieSpawner")
	assert_gt(other_spawner.test_zombie_count, 0)
	var count := 0
	for node in other.get_children():
		if node is Zombie:
			count += 1
	assert_eq(count, other_spawner.test_zombie_count, "temporary zombies until waves exist")


func test_alerted_zombie_chases_the_player() -> void:
	var zombie := _spawn(Vector3(0.0, 0.0, -9.0))
	var start := zombie.global_position.distance_to(player.global_position)
	await wait_seconds(1.5)
	assert_eq(zombie.state, Zombie.State.CHASE)
	assert_lt(zombie.global_position.distance_to(player.global_position), start - 1.5, "RF-64: it closes in")


func test_idle_zombie_detects_player_in_radius_with_line_of_sight() -> void:
	var near := _spawn(Vector3(0.0, 0.0, -10.0), false)
	var far := _spawn(Vector3(0.0, 0.0, -(near.config.detection_radius + 8.0)), false)
	await wait_seconds(0.6)
	assert_eq(near.state, Zombie.State.CHASE, "RF-63: detected inside the radius")
	assert_eq(far.state, Zombie.State.IDLE, "too far to notice the player")


func test_zombie_attacks_player_even_while_carrying() -> void:
	(player.get_node("PlayerCarry") as PlayerCarry).pick_up()
	var zombie := _spawn(Vector3(0.0, 0.0, -1.2))
	zombie.config.attack_hit_delay = 0.1
	await wait_seconds(0.6)
	assert_eq(zombie.state, Zombie.State.ATTACK)
	assert_almost_eq(player.health.current_health,
		player.health.max_health - zombie.config.damage_to_player, 0.01, "RF-65")


func test_damage_staggers_and_kills() -> void:
	var zombie := _spawn(Vector3(0.0, 0.0, -6.0))
	watch_signals(EventBus)
	zombie.health.take_damage(10.0, player)
	assert_eq(zombie.state, Zombie.State.HIT, "RF-67: reacts to hits")
	zombie.health.take_damage(zombie.health.max_health, player)
	assert_eq(zombie.state, Zombie.State.DEAD, "RF-66")
	assert_signal_emitted(EventBus, "zombie_killed")
	assert_false(zombie.is_in_group(&"zombies"), "no longer counted as alive")
	assert_eq(zombie.collision_layer, 0, "the body does not block shots or the player")


func test_dead_zombie_can_drop_ammo_and_disappears() -> void:
	var zombie := _spawn(Vector3(0.0, 0.0, -6.0))
	zombie.config.ammo_drop_chance = 1.0
	zombie.config.corpse_lifetime = 0.4
	zombie.health.take_damage(zombie.health.max_health, player)
	await wait_physics_frames(3)
	var drops: Array[AmmoPickup] = []
	for node in zombie.get_parent().get_children():
		if node is AmmoPickup:
			drops.append(node)
	assert_eq(drops.size(), 1, "RF-55")
	assert_eq(drops[0].amount, zombie.config.ammo_drop_amount)
	assert_eq(drops[0].lifetime, zombie.config.ammo_drop_lifetime, "RF-57: it expires")
	await wait_seconds(0.6)
	assert_false(is_instance_valid(zombie), "RF-68: the body disappears")


func test_shotgun_kills_a_zombie() -> void:
	# CA-08 (partial): the shotgun damages zombies through the shared hit lookup.
	var zombie := _spawn(Vector3(0.0, 0.0, -3.0))
	await wait_physics_frames(2)
	var shotgun: Shotgun = player.get_node("Shotgun")
	player.rotation.y = 0.0
	player.head.rotation.x = deg_to_rad(-12.0)
	var before := zombie.health.current_health
	shotgun._fire_pellet()
	shotgun._fire_pellet()
	shotgun._fire_pellet()
	assert_lt(zombie.health.current_health, before, "pellets hit the zombie")


func test_axe_knockback_pushes_zombie() -> void:
	var zombie := _spawn(Vector3(0.0, 0.0, -3.0))
	zombie.config.run_speed = 0.0
	zombie.config.walk_speed = 0.0
	var start := zombie.global_position
	zombie.apply_knockback(Vector3(0.0, 0.0, -1.0))
	await wait_seconds(0.6)
	assert_lt(zombie.global_position.z, start.z - 0.6, "pushed about one meter back")


func test_player_dies_and_respawns_at_cafeteria() -> void:
	# RF-80 to RF-83, CA-11.
	player.config = player.config.duplicate()
	player.config.respawn_delay = 0.3
	var carry: PlayerCarry = player.get_node("PlayerCarry")
	carry.pick_up()
	watch_signals(EventBus)
	player.health.take_damage(player.health.max_health)
	assert_signal_emitted(EventBus, "player_died")
	assert_false(player.input_enabled, "no control while dead")
	assert_false(carry.is_carrying(), "RF-14: the crate is lost")
	assert_eq(GameManager.state, GameManager.GameState.PLAYING, "RF-83: the match goes on")
	await wait_seconds(0.6)
	assert_signal_emitted(EventBus, "player_respawned")
	var spawn: Vector3 = (game.get_node("ZooLevel") as ZooLevel).player_spawn.global_position
	assert_almost_eq(player.global_position.distance_to(spawn), 0.0, 0.5, "RF-80: back at the cafeteria")
	assert_eq(player.health.current_health, player.health.max_health, "RF-81: full health")
	assert_true(player.input_enabled)


func test_zombies_stop_attacking_a_dead_player() -> void:
	var zombie := _spawn(Vector3(0.0, 0.0, -1.2))
	player.health.take_damage(player.health.max_health)
	await wait_seconds(0.4)
	assert_eq(zombie.state, Zombie.State.IDLE)
