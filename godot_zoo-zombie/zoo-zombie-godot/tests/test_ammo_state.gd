extends GutTest
## AmmoState: magazine, reserve and reload rules (spec 001 RF-51, CA-12).


func _state(magazine_size: int = 6, starting_reserve: int = 10, max_reserve: int = 12) -> AmmoState:
	var config := ShotgunConfig.new()
	config.magazine_size = magazine_size
	config.starting_reserve = starting_reserve
	config.max_reserve = max_reserve
	return AmmoState.new(config)


func test_starts_with_full_magazine_and_starting_reserve() -> void:
	var ammo := _state()
	assert_eq(ammo.magazine, 6)
	assert_eq(ammo.reserve, 10)


func test_starting_reserve_is_capped() -> void:
	assert_eq(_state(6, 99, 12).reserve, 12)


func test_consume_until_empty() -> void:
	var ammo := _state(2)
	assert_true(ammo.consume_shell())
	assert_true(ammo.consume_shell())
	assert_false(ammo.consume_shell(), "cannot fire with an empty magazine")
	assert_eq(ammo.magazine, 0)


func test_reload_moves_shells_from_reserve() -> void:
	var ammo := _state(6, 10)
	for i in 4:
		ammo.consume_shell()
	assert_eq(ammo.reload(), 4)
	assert_eq(ammo.magazine, 6)
	assert_eq(ammo.reserve, 6)


func test_partial_reload_when_reserve_is_short() -> void:
	var ammo := _state(6, 2)
	for i in 6:
		ammo.consume_shell()
	assert_eq(ammo.reload(), 2)
	assert_eq(ammo.magazine, 2)
	assert_eq(ammo.reserve, 0)
	assert_eq(ammo.reload(), 0, "nothing left to load")


func test_add_reserve_respects_maximum() -> void:
	var ammo := _state(6, 10, 12)
	assert_eq(ammo.add_reserve(6), 2)
	assert_eq(ammo.reserve, 12)
	assert_eq(ammo.add_reserve(4), 0, "full reserve takes nothing")
	assert_eq(ammo.add_reserve(-3), 0)
