extends GutTest
## AmmoSpawnDirector: active crates, glow and respawn at a different point (RF-58, RF-59).

const PICKUP_SCENE := preload("res://scenes/pickups/ammo_pickup.tscn")

var director: AmmoSpawnDirector
var points: Array[Marker3D] = []


func _setup(active_count: int, point_count: int) -> void:
	var config := AmmoSpawnConfig.new()
	config.active_count = active_count
	config.respawn_delay = 0.2
	director = AmmoSpawnDirector.new()
	director.config = config
	director.pickup_scene = PICKUP_SCENE
	add_child_autofree(director)
	points.clear()
	for i in point_count:
		var marker := Marker3D.new()
		marker.position = Vector3(i * 10.0, 0.0, 0.0)
		add_child_autofree(marker)
		points.append(marker)
	director.setup(points)


func _pickup_at(point: Marker3D) -> AmmoPickup:
	for child in point.get_children():
		if child is AmmoPickup and not child.is_queued_for_deletion():
			return child
	return null


func test_spawns_active_count_with_glow() -> void:
	_setup(4, 15)
	assert_eq(director.active_count(), 4)
	var pickup := _pickup_at(director.occupied_points()[0])
	assert_not_null(pickup)
	assert_eq(pickup.amount, director.config.shells_per_crate)
	assert_eq(pickup.lifetime, 0.0, "map crates never expire")
	assert_eq(pickup.find_children("*", "OmniLight3D", true, false).size(), 1, "RF-59: glowing light")


func test_never_more_crates_than_points() -> void:
	_setup(4, 2)
	assert_eq(director.active_count(), 2)


func test_respawns_at_a_different_point() -> void:
	_setup(1, 2)
	var first := director.occupied_points()[0]
	var pickup := _pickup_at(first)
	pickup.collected.emit(pickup)
	pickup.queue_free()
	assert_eq(director.active_count(), 0)
	assert_eq(director.pending_respawns(), 1)
	await wait_seconds(0.35)
	assert_eq(director.active_count(), 1)
	assert_ne(director.occupied_points()[0], first, "RF-58: a different point")
