extends GutTest
## Stamina of escaped animals (spec 001 RF-41, RF-42).


func test_running_drains_and_rest_restores() -> void:
	var stamina := Stamina.new(100.0, 20.0, 10.0, 0.5)
	stamina.tick(2.0, true)
	assert_almost_eq(stamina.value, 60.0, 0.001)
	stamina.tick(1.0, false)
	assert_almost_eq(stamina.value, 70.0, 0.001)
	stamina.tick(100.0, false)
	assert_almost_eq(stamina.value, 100.0, 0.001, "capped at the maximum")


func test_tired_at_zero_until_recovery_ratio() -> void:
	var stamina := Stamina.new(100.0, 50.0, 10.0, 0.5)
	watch_signals(stamina)
	stamina.tick(2.5, true)
	assert_true(stamina.is_tired, "RF-42: tired at 0")
	assert_false(stamina.can_run())
	assert_signal_emitted_with_parameters(stamina, "tired_changed", [true])
	stamina.tick(4.0, true)
	assert_true(stamina.is_tired, "still tired at 40 %")
	assert_almost_eq(stamina.value, 40.0, 0.001, "trying to run while tired does not drain")
	stamina.tick(1.0, false)
	assert_false(stamina.is_tired, "recovered at 50 %")


func test_from_config() -> void:
	var config := AnimalConfig.new()
	var stamina := Stamina.from_config(config)
	assert_eq(stamina.max_value, config.max_stamina)
	assert_eq(stamina.recovery_ratio, config.tired_recovery_ratio)
