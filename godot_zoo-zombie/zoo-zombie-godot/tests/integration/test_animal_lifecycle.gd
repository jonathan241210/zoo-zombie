extends GutTest
## Hunger, weakness and death of the animals in the real game scene
## (spec 001 phase 4: RF-21 to RF-29, CA-02, CA-17 to CA-20).

const GAME := preload("res://scenes/main/game.tscn")

var game: Node3D
var player: PlayerController


func before_each() -> void:
	game = GAME.instantiate()
	(game.get_node("WaveManager") as WaveManager).enabled = false
	add_child_autofree(game)
	await wait_physics_frames(10)
	player = game.get_node("Player")
	player.input_enabled = false


func _animal(animal_id: StringName) -> Animal:
	for node in game.get_node("ZooLevel").get_children():
		if node is Animal and node.config.animal_id == animal_id:
			return node
	return null


func test_satiety_drains_then_hunger_damage_starts() -> void:
	# CA-19: no damage during the grace period, then damage at the configured rate.
	var needs := AnimalNeeds.new()
	var config := AnimalConfig.new()
	config.grace_period = 10.0
	config.starvation_damage_per_second = 2.0
	needs.configure(config)
	assert_almost_eq(needs.satiety_ratio(), 1.0, 0.001, "starts full")
	assert_eq(needs.tick(4.0), 0.0)
	assert_almost_eq(needs.satiety_ratio(), 0.6, 0.001)
	assert_almost_eq(needs.tick(8.0), 4.0, 0.001, "only the 2 s past the grace period hurt")
	assert_almost_eq(needs.tick(1.0), 2.0, 0.001)
	needs.feed()
	assert_almost_eq(needs.satiety_ratio(), 1.0, 0.001, "feeding refills satiety")


func test_feeding_at_full_health_only_resets_satiety() -> void:
	# CA-18
	var elephant := _animal(&"elephant")
	elephant.needs.satiety_remaining = 1.0
	assert_true(elephant.feed())
	assert_almost_eq(elephant.health.current_health, elephant.health.max_health, 0.001)
	assert_almost_eq(elephant.needs.satiety_ratio(), 1.0, 0.01)


func test_weak_state_below_threshold() -> void:
	# RF-27 / CA-02: weak below the threshold, slower, own animation; heals back out of it.
	var elephant := _animal(&"elephant")
	watch_signals(EventBus)
	assert_false(elephant.is_weak)
	var normal_speed := elephant.get_move_speed()
	var threshold_health := elephant.health.max_health * elephant.config.weak_threshold
	elephant.health.take_damage(elephant.health.max_health - threshold_health + 1.0)
	assert_true(elephant.is_weak)
	assert_signal_emitted_with_parameters(EventBus, "animal_weak_changed", [&"elephant", true])
	assert_almost_eq(elephant.get_move_speed(), normal_speed * elephant.config.weak_speed_multiplier, 0.001)
	assert_eq(elephant._idle_animation(), &"weak")
	elephant.health.heal(elephant.health.max_health)
	assert_false(elephant.is_weak)
	assert_almost_eq(elephant.get_move_speed(), normal_speed, 0.001)


func test_player_weapons_do_not_hurt_the_giraffe() -> void:
	# CA-17 (RF-28): the shotgun finds no health pool on the giraffe.
	var giraffe := _animal(&"giraffe")
	var elephant := _animal(&"elephant")
	assert_false(giraffe.can_receive_damage_from(player))
	assert_null(HealthComponent.find_for_hit(giraffe, player))
	assert_not_null(HealthComponent.find_for_hit(elephant, player), "the exception is per species")


func test_death_emits_then_removes_animal_and_feeder() -> void:
	# CA-20 (RF-29): signal with position first, then animal and feeder disappear.
	var elephant := _animal(&"elephant")
	var feeder := elephant.feeder
	var position := elephant.global_position
	watch_signals(EventBus)
	elephant.health.take_damage(elephant.health.max_health)
	assert_signal_emitted(EventBus, "animal_died")
	var params: Array = get_signal_parameters(EventBus, "animal_died")
	assert_eq(params[0], &"elephant")
	assert_almost_eq((params[1] as Vector3).distance_to(position), 0.0, 0.01)
	assert_eq(elephant.state, Animal.State.DEAD)
	assert_false(elephant.can_be_fed())
	var despawn_delay := maxf(elephant.config.death_despawn_delay,
		elephant._animation.get_animation(&"death").length)
	await wait_physics_frames(2)
	assert_false(is_instance_valid(feeder), "feeder removed")
	assert_true(is_instance_valid(elephant), "animal stays while the death animation plays")
	await wait_seconds(despawn_delay + 0.5)
	assert_false(is_instance_valid(elephant), "animal removed after its death animation")
