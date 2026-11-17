extends GutTest
## FoodCrateDirector: max active crates and respawn after pickup (spec 001 RF-10, RF-13).

const CRATE_SCENE := preload("res://scenes/pickups/food_crate.tscn")

var director: FoodCrateDirector
var spawns: Array[Marker3D] = []


func before_each() -> void:
	var config := FoodCrateConfig.new()
	config.max_active = 3
	config.respawn_delay = 0.2
	director = FoodCrateDirector.new()
	director.config = config
	director.crate_scene = CRATE_SCENE
	add_child_autofree(director)
	spawns.clear()
	for i in 6:
		var marker := Marker3D.new()
		marker.position = Vector3(i * 5.0, 0.0, 0.0)
		add_child_autofree(marker)
		spawns.append(marker)


func _crates() -> Array[FoodCrate]:
	var result: Array[FoodCrate] = []
	for marker in spawns:
		for child in marker.get_children():
			if child is FoodCrate and not child.is_queued_for_deletion():
				result.append(child)
	return result


func test_fills_up_to_max_active() -> void:
	director.setup(spawns)
	assert_eq(director.active_count(), 3)
	assert_eq(_crates().size(), 3)


func test_never_two_crates_on_one_point() -> void:
	director.setup(spawns)
	for marker in spawns:
		assert_lte(marker.get_child_count(), 1)


func test_respawns_after_delay() -> void:
	director.setup(spawns)
	var crate := _crates()[0]
	crate.picked_up.emit(crate)
	crate.queue_free()
	assert_eq(director.active_count(), 2)
	assert_eq(director.pending_respawns(), 1)
	await wait_seconds(0.4)
	assert_eq(director.active_count(), 3, "RF-13: respawned after respawn_delay")
	assert_eq(director.pending_respawns(), 0)
