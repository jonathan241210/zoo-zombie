extends GutTest
## Waves in the real game scene with shortened timings (spec 001 phase 8:
## RF-70 to RF-76, CA-09, CA-10).

const GAME := preload("res://scenes/main/game.tscn")

var game: Node3D
var waves: WaveManager


func _fast_waves() -> WaveSetConfig:
	# Copy each wave: duplicate(true) keeps the external wave resources shared, and
	# changing them would leak into other tests through the resource cache.
	var source := load("res://config/waves/wave_set.tres") as WaveSetConfig
	var wave_set := WaveSetConfig.new()
	wave_set.initial_countdown = 0.2
	wave_set.break_duration = 0.4
	wave_set.min_spawn_distance = 0.0
	var copies: Array[WaveConfig] = []
	for original: WaveConfig in source.waves:
		copies.append(original.duplicate() as WaveConfig)
	wave_set.waves = copies
	for wave: WaveConfig in wave_set.waves:
		wave.duration = 1.2
		wave.spawn_interval = 0.15
		wave.total_zombies = 4
		wave.max_alive = 3
		wave.breaker_ratio = 0.5
	return wave_set


func before_each() -> void:
	game = GAME.instantiate()
	waves = game.get_node("WaveManager")
	waves.config = _fast_waves()
	# The end screen would pause the tree and stop the test waits.
	(game.get_node("HUD/EndScreen") as EndScreen).pause_game = false
	add_child_autofree(game)
	# The start tutorial pauses the tree; dismiss it so the match runs.
	(game.get_node("HUD/TutorialPopup") as TutorialPopup)._continue_game()
	await wait_physics_frames(3)
	(game.get_node("Player") as PlayerController).input_enabled = false


func _zombies() -> Array[Zombie]:
	var result: Array[Zombie] = []
	for node in get_tree().get_nodes_in_group(&"zombies"):
		result.append(node as Zombie)
	return result


func test_three_waves_then_victory() -> void:
	# RF-70, RF-72, RF-76, CA-09, CA-10.
	watch_signals(EventBus)
	var game_scene_waves := waves.config.waves
	await wait_seconds(0.6)
	assert_signal_emitted_with_parameters(EventBus, "wave_started", [1])
	var alive := _zombies()
	assert_lte(alive.size(), game_scene_waves[0].max_alive, "RF-71: max alive")
	assert_gt(alive.size(), 0)
	var roles := {}
	for zombie in alive:
		roles[zombie.role] = true
	await wait_seconds(1.0)
	assert_signal_emitted_with_parameters(EventBus, "wave_break_started", [2])
	var survivor := alive[0]
	await wait_seconds(0.6)
	assert_signal_emitted_with_parameters(EventBus, "wave_started", [2])
	assert_true(is_instance_valid(survivor) and survivor.is_in_group(&"zombies"), "RF-72: zombies persist")
	await wait_seconds(3.4)
	assert_signal_emitted_with_parameters(EventBus, "wave_started", [3])
	assert_signal_emitted(EventBus, "game_won")
	assert_eq(GameManager.state, GameManager.GameState.WON, "RF-76")
	assert_eq(get_signal_parameters(EventBus, "wave_started")[0], 3, "exactly three waves")


func test_wave_zombies_use_the_wave_multipliers() -> void:
	waves.config.waves[0].speed_multiplier = 1.5
	waves.config.waves[0].health_multiplier = 2.0
	await wait_seconds(0.5)
	var zombie := _zombies()[0]
	assert_eq(zombie.speed_multiplier, 1.5)
	assert_almost_eq(zombie.health.max_health, zombie.config.max_health * 2.0, 0.01)


func test_breaker_share_follows_the_wave_ratio() -> void:
	await wait_seconds(1.0)
	var breakers := 0
	var total := 0
	for zombie in _zombies():
		total += 1
		if zombie.role == Zombie.Role.BREAKER:
			breakers += 1
	assert_gt(total, 1)
	assert_between(breakers, 1, total - 1, "RF-71: mix of breakers and hunters at 50 %")


func test_zombie_counter_is_published() -> void:
	watch_signals(EventBus)
	await wait_seconds(0.8)
	assert_signal_emitted(EventBus, "zombie_count_changed")
	var hud: WaveHud = game.get_node("HUD/WaveHud")
	assert_string_contains(hud.text, "1/3")


func test_no_victory_if_both_animals_died() -> void:
	for node in game.get_node("ZooLevel").get_children():
		if node is Animal:
			(node as Animal).health.take_damage(1000.0)
	await wait_physics_frames(2)
	assert_eq(GameManager.state, GameManager.GameState.LOST)
	watch_signals(EventBus)
	await wait_seconds(5.0)
	assert_signal_not_emitted(EventBus, "game_won")
