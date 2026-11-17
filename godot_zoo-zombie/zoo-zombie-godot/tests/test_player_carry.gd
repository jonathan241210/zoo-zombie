extends GutTest
## PlayerCarry: ARMED/CARRYING rules (spec 001 RF-04, RF-05, RF-12, RF-14; CA-01).

var carry: PlayerCarry


func before_each() -> void:
	carry = PlayerCarry.new()
	add_child_autofree(carry)


func test_starts_armed_and_can_use_weapons() -> void:
	assert_eq(carry.state, PlayerCarry.State.ARMED)
	assert_true(carry.can_use_weapons())
	assert_false(carry.is_carrying())


func test_pick_up_blocks_weapons() -> void:
	assert_true(carry.pick_up())
	assert_true(carry.is_carrying())
	assert_false(carry.can_use_weapons(), "CA-01: no shooting while carrying")


func test_only_one_crate_at_a_time() -> void:
	carry.pick_up()
	assert_false(carry.pick_up(), "RF-12")


func test_consume_restores_weapons() -> void:
	carry.pick_up()
	assert_true(carry.consume())
	assert_true(carry.can_use_weapons())
	assert_false(carry.consume(), "nothing left to consume")


func test_crate_lost_on_player_death() -> void:
	carry.pick_up()
	EventBus.player_died.emit()
	assert_false(carry.is_carrying(), "RF-14")


func test_emits_global_carry_signal() -> void:
	watch_signals(EventBus)
	carry.pick_up()
	assert_signal_emitted_with_parameters(EventBus, "player_carry_changed", [true])
