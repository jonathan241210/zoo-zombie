extends GutTest
## PlayerController: jump and sprint rules (spec 005 RF-02, RF-03, RF-10 to RF-13; CA-01, CA-02).

var player: PlayerController
var config: PlayerConfig


func before_each() -> void:
	config = PlayerConfig.new()
	player = PlayerController.new()
	player.config = config


func after_each() -> void:
	player.free()


func test_jump_velocity_reaches_requested_height() -> void:
	var velocity := PlayerController.jump_velocity(1.0, 20.0)
	# h = v^2 / (2 g)
	assert_almost_eq(velocity * velocity / (2.0 * 20.0), 1.0, 0.001)


func test_jump_velocity_grows_with_height() -> void:
	assert_gt(PlayerController.jump_velocity(2.0, 20.0), PlayerController.jump_velocity(1.0, 20.0))


func test_can_jump_when_armed_and_enabled() -> void:
	assert_true(player.can_jump())


func test_cannot_jump_while_carrying() -> void:
	player.is_carrying = true
	assert_false(player.can_jump(), "RF-03: no jumping while carrying a crate")


func test_cannot_jump_when_input_disabled() -> void:
	player.input_enabled = false
	assert_false(player.can_jump())


func test_walk_speed_without_sprint() -> void:
	assert_eq(player.get_target_speed(Vector2(0.0, -1.0)), config.walk_speed)


func test_carry_speed_has_priority() -> void:
	player.is_carrying = true
	Input.action_press(&"sprint")
	assert_eq(player.get_target_speed(Vector2(0.0, -1.0)), config.carry_speed, "RF-13")
	Input.action_release(&"sprint")


func test_sprint_speed_when_moving_forward() -> void:
	Input.action_press(&"sprint")
	assert_eq(player.get_target_speed(Vector2(0.0, -1.0)), config.sprint_speed)
	Input.action_release(&"sprint")


func test_no_sprint_backwards_by_default() -> void:
	Input.action_press(&"sprint")
	assert_eq(player.get_target_speed(Vector2(0.0, 1.0)), config.walk_speed, "RF-12")
	Input.action_release(&"sprint")


func test_sprint_backwards_when_allowed() -> void:
	config.allow_backward_sprint = true
	Input.action_press(&"sprint")
	assert_eq(player.get_target_speed(Vector2(0.0, 1.0)), config.sprint_speed)
	Input.action_release(&"sprint")
