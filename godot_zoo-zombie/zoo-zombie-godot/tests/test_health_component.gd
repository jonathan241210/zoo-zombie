extends GutTest
## Unit tests for HealthComponent (spec 001: RF-02, RF-43/RF-66 base behaviour).

var health: HealthComponent


func before_each() -> void:
	health = HealthComponent.new()
	health.max_health = 100.0
	add_child_autofree(health)


func test_starts_full() -> void:
	assert_eq(health.current_health, 100.0)
	assert_false(health.is_dead)


func test_take_damage_reduces_health_and_returns_applied() -> void:
	var applied := health.take_damage(30.0)
	assert_eq(applied, 30.0)
	assert_eq(health.current_health, 70.0)


func test_damage_is_clamped_and_kills_once() -> void:
	watch_signals(health)
	var applied := health.take_damage(250.0)
	assert_eq(applied, 100.0)
	assert_eq(health.current_health, 0.0)
	assert_true(health.is_dead)
	assert_signal_emit_count(health, "died", 1)
	assert_eq(health.take_damage(10.0), 0.0, "dead pools ignore damage")
	assert_signal_emit_count(health, "died", 1)


func test_heal_does_not_exceed_max() -> void:
	health.take_damage(40.0)
	var healed := health.heal(100.0)
	assert_eq(healed, 40.0)
	assert_eq(health.current_health, 100.0)


func test_heal_ignored_when_dead() -> void:
	health.take_damage(100.0)
	assert_eq(health.heal(50.0), 0.0)
	assert_eq(health.current_health, 0.0)


func test_non_positive_amounts_are_ignored() -> void:
	watch_signals(health)
	health.take_damage(0.0)
	health.take_damage(-5.0)
	health.heal(-5.0)
	assert_eq(health.current_health, 100.0)
	assert_signal_not_emitted(health, "health_changed")


func test_reset_revives_with_new_max() -> void:
	health.take_damage(100.0)
	health.reset(140.0)
	assert_false(health.is_dead)
	assert_eq(health.max_health, 140.0)
	assert_eq(health.current_health, 140.0)


func test_ratio() -> void:
	health.take_damage(25.0)
	assert_almost_eq(health.get_ratio(), 0.75, 0.0001)
