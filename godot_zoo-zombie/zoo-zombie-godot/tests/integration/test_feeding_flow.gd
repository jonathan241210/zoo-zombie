extends GutTest
## End-to-end feeding loop in the real game scene (spec 001 phase 3: CA-01, CA-03).
## Pick up a crate -> carry (weapons blocked, slower) -> feed the giraffe from outside
## its fence -> it heals, eats, and the player can use weapons again.

const GAME := preload("res://scenes/main/game.tscn")

var game: Node3D
var player: PlayerController
var carry: PlayerCarry
var interactor: PlayerInteractor


func before_each() -> void:
	game = GAME.instantiate()
	add_child_autofree(game)
	await wait_physics_frames(10)
	player = game.get_node("Player")
	carry = player.get_node("PlayerCarry")
	interactor = player.get_node("PlayerInteractor")
	player.input_enabled = false


func _animal(animal_id: StringName) -> Animal:
	for node in game.get_node("ZooLevel").get_children():
		if node is Animal and node.config.animal_id == animal_id:
			return node
	return null


func _first_crate() -> FoodCrate:
	for marker in (game.get_node("ZooLevel") as ZooLevel).get_food_crate_spawns():
		for child in marker.get_children():
			if child is FoodCrate:
				return child
	return null


func _stand_facing(position: Vector3, target: Vector3) -> void:
	player.global_position = position
	var to_target := target - position
	player.rotation.y = atan2(-to_target.x, -to_target.z)
	await wait_physics_frames(6)


func test_animals_spawn_inside_their_enclosures() -> void:
	for animal_id: StringName in [&"giraffe", &"elephant"]:
		var animal := _animal(animal_id)
		assert_not_null(animal, "%s spawned" % animal_id)
		assert_eq(animal.enclosure.map_name, animal.config.home_enclosure)
		assert_true(animal.enclosure.is_inside(animal.global_position), "%s inside its fence" % animal_id)
		assert_not_null(animal.feeder, "%s has a feeder" % animal_id)


func test_full_feeding_loop() -> void:
	var crate := _first_crate()
	assert_not_null(crate)
	await _stand_facing(crate.global_position + Vector3(0, 0.1, 1.2), crate.global_position)
	assert_eq(interactor.focused.prompt_key if interactor.focused else "", "PROMPT_PICK_UP")
	interactor.focused.interact(player)
	await wait_physics_frames(3)
	assert_true(carry.is_carrying())
	assert_false(carry.can_use_weapons(), "CA-01")
	assert_eq(player.get_target_speed(Vector2(0, -1)), player.config.carry_speed)
	assert_null(interactor.focused, "no stale pick-up prompt while carrying")

	var giraffe := _animal(&"giraffe")
	giraffe.health.take_damage(40.0)
	watch_signals(EventBus)
	var feeder_pos := giraffe.feeder.global_position
	await _stand_facing(feeder_pos - giraffe.feeder.global_basis.z * 2.6 + Vector3.UP * 0.1, feeder_pos)
	assert_eq(interactor.focused.prompt_key if interactor.focused else "", "PROMPT_FEED")
	interactor.focused.interact(player)
	await wait_physics_frames(3)
	assert_signal_emitted_with_parameters(EventBus, "animal_fed", [&"giraffe"])
	assert_almost_eq(giraffe.health.current_health, 100.0, 0.01, "CA-03: healed")
	assert_true(carry.can_use_weapons(), "CA-01: weapons back after feeding")
	assert_eq(giraffe.state, Animal.State.EATING)


func test_cannot_feed_without_food() -> void:
	var giraffe := _animal(&"giraffe")
	var feeder_pos := giraffe.feeder.global_position
	await _stand_facing(feeder_pos - giraffe.feeder.global_basis.z * 2.6 + Vector3.UP * 0.1, feeder_pos)
	assert_null(interactor.focused, "no feed prompt with empty hands")


func _press_interact() -> void:
	# Real key events through the viewport, so the input path is tested, not just drop().
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		event.keycode = KEY_E
		event.pressed = pressed
		Input.parse_input_event(event)
		await wait_physics_frames(3)


func test_e_key_drops_and_crate_can_be_picked_up_again() -> void:
	# Spec 004 RF-01 to RF-04: E drops the crate away from feeders; it can be taken again.
	var director: FoodCrateDirector = game.get_node("FoodCrateDirector")
	assert_eq(carry.food_crate_director, director, "director wired by the game root")
	player.input_enabled = true
	player.global_position = Vector3(10.0, 1.6, 9.0)
	await wait_physics_frames(4)
	carry.pick_up()
	await wait_physics_frames(3)
	var active_before := director.active_count()
	watch_signals(carry)
	await _press_interact()
	assert_false(carry.is_carrying(), "E drops the crate")
	assert_signal_emitted(carry, "crate_dropped")
	var dropped: FoodCrate = get_signal_parameters(carry, "crate_dropped")[0]
	assert_true(dropped.is_inside_tree())
	assert_eq(director.active_count(), active_before + 1, "dropped crate counts as active")
	await _stand_facing(dropped.global_position + Vector3(0, 0.1, 1.2), dropped.global_position)
	assert_eq(interactor.focused.prompt_key if interactor.focused else "", "PROMPT_PICK_UP")
	await _press_interact()
	assert_true(carry.is_carrying(), "picked up again with E")
