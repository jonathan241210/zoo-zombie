extends GutTest
## Coin balance rules (spec 001 RF-90 to RF-92, CA-22).

var manager: ScoreManager
var config: ScoreConfig


func before_each() -> void:
	config = ScoreConfig.new()
	config.zombie_kill = 5
	config.recapture = 200
	config.ammo_pickup = 0
	config.player_death_penalty = 100
	config.animal_death_penalty = 300
	manager = ScoreManager.new()
	manager.config = config
	add_child_autofree(manager)


func test_starts_at_zero() -> void:
	assert_eq(manager.coins, 0)


func test_zombie_kill_and_feeding_reward_five() -> void:
	EventBus.zombie_killed.emit(null)
	EventBus.coins_earned.emit(5)
	assert_eq(manager.coins, 10)


func test_recapture_uses_configured_reward() -> void:
	EventBus.animal_recaptured.emit(&"giraffe", null)
	assert_eq(manager.coins, 200)


func test_ammo_pickup_gives_nothing_by_default() -> void:
	EventBus.ammo_collected.emit(4)
	assert_eq(manager.coins, 0)
	config.ammo_pickup = 2
	EventBus.ammo_collected.emit(4)
	assert_eq(manager.coins, 2)


func test_penalties_subtract_but_never_below_zero() -> void:
	EventBus.animal_recaptured.emit(&"giraffe", null)
	EventBus.player_died.emit()
	assert_eq(manager.coins, 100)
	EventBus.animal_died.emit(&"elephant", Vector3.ZERO)
	assert_eq(manager.coins, 0)
	EventBus.player_died.emit()
	assert_eq(manager.coins, 0)


func test_emits_score_changed_with_balance() -> void:
	watch_signals(EventBus)
	EventBus.zombie_killed.emit(null)
	assert_signal_emitted_with_parameters(EventBus, "score_changed", [5])
