extends GutTest
## Weapons in the real game scene (spec 001 phase 5): switching, carry lock, axe arc and
## ammo pickups (RF-05, RF-56, RF-57, RF-5A, RF-5B, CA-16).

const GAME := preload("res://scenes/main/game.tscn")
const PICKUP_SCENE := preload("res://scenes/pickups/ammo_pickup.tscn")
const ZOMBIE_LAYER := 1 << 2

var game: Node3D
var player: PlayerController
var weapons: WeaponManager
var axe: Axe
var shotgun: Shotgun
var carry: PlayerCarry


func before_each() -> void:
	game = GAME.instantiate()
	add_child_autofree(game)
	await wait_physics_frames(10)
	player = game.get_node("Player")
	weapons = player.get_node("WeaponManager")
	axe = player.get_node("Axe")
	shotgun = player.get_node("Shotgun")
	carry = player.get_node("PlayerCarry")
	# Open ground in front of the cafeteria, facing -Z.
	player.global_position = Vector3(10.0, 1.6, 9.0)
	player.rotation.y = 0.0
	player.head.rotation.x = 0.0
	await wait_physics_frames(4)


## A static stand-in for a zombie: body on the zombie layer with a HealthComponent.
func _dummy(offset: Vector3) -> HealthComponent:
	var body := StaticBody3D.new()
	body.collision_layer = ZOMBIE_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	shape.shape = capsule
	shape.position = Vector3.UP * 0.9
	body.add_child(shape)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	body.add_child(health)
	game.add_child(body)
	body.global_position = player.global_position + offset
	return health


func test_starts_with_shotgun() -> void:
	assert_eq(weapons.current, WeaponManager.SHOTGUN)
	assert_true(shotgun.active)
	assert_false(axe.active)


func test_switch_to_axe_and_back() -> void:
	watch_signals(EventBus)
	weapons.switch_to(WeaponManager.AXE)
	assert_true(weapons.is_switching)
	assert_false(shotgun.active, "no weapon usable mid-switch")
	assert_false(axe.active)
	await wait_seconds(player.config.weapon_switch_time + 0.1)
	assert_eq(weapons.current, WeaponManager.AXE)
	assert_true(axe.active)
	assert_signal_emitted_with_parameters(EventBus, "weapon_changed", [WeaponManager.AXE])
	weapons.switch_to(WeaponManager.SHOTGUN)
	await wait_seconds(player.config.weapon_switch_time + 0.1)
	assert_true(shotgun.active)


func test_cannot_switch_or_swing_while_carrying() -> void:
	carry.pick_up()
	assert_false(await weapons.switch_to(WeaponManager.AXE), "RF-05")
	assert_eq(weapons.current, WeaponManager.SHOTGUN)
	assert_false(shotgun.fire(), "RF-05: no firing while carrying")
	carry.consume()
	assert_true(shotgun.fire(), "RF-5B: the weapon is back after feeding")


func test_axe_hits_nearest_targets_in_front_only() -> void:
	weapons.switch_to(WeaponManager.AXE)
	await wait_seconds(player.config.weapon_switch_time + 0.1)
	var near := _dummy(Vector3(0.0, 0.0, -1.2))
	var mid := _dummy(Vector3(0.6, 0.0, -1.6))
	var far := _dummy(Vector3(-0.6, 0.0, -2.0))
	var behind := _dummy(Vector3(0.0, 0.0, 1.2))
	var out_of_range := _dummy(Vector3(0.0, 0.0, -(axe.config.max_range + 1.5)))
	await wait_physics_frames(3)
	var damaged := axe.strike()
	assert_eq(damaged.size(), axe.config.max_targets, "RF-5A: capped targets per swing")
	assert_true(near in damaged)
	assert_true(mid in damaged)
	assert_false(far in damaged, "only the nearest ones")
	assert_false(behind in damaged, "outside the frontal arc")
	assert_false(out_of_range in damaged)
	assert_almost_eq(near.current_health, near.max_health - axe.config.damage, 0.01)


func test_axe_respects_swing_interval() -> void:
	weapons.switch_to(WeaponManager.AXE)
	await wait_seconds(player.config.weapon_switch_time + 0.1)
	assert_true(axe.can_swing())
	axe.swing()
	assert_false(axe.can_swing(), "slow weapon: wait between swings")


func test_ammo_pickup_fills_reserve_and_keeps_the_rest() -> void:
	shotgun.ammo.reserve = shotgun.ammo.max_reserve - 2
	var pickup := PICKUP_SCENE.instantiate() as AmmoPickup
	pickup.configure(6, 0.0)
	game.add_child(pickup)
	pickup.global_position = player.global_position
	await wait_physics_frames(4)
	assert_eq(shotgun.ammo.reserve, shotgun.ammo.max_reserve, "RF-56")
	assert_true(is_instance_valid(pickup), "shells that did not fit stay")
	assert_eq(pickup.amount, 4)
	shotgun.ammo.reserve -= 4
	await wait_physics_frames(4)
	assert_false(is_instance_valid(pickup) and not pickup.is_queued_for_deletion(), "collected once there is room")


func test_dropped_ammo_expires() -> void:
	var pickup := PICKUP_SCENE.instantiate() as AmmoPickup
	pickup.configure(4, 0.3)
	game.add_child(pickup)
	pickup.global_position = player.global_position + Vector3(0.0, 0.0, -8.0)
	await wait_seconds(0.5)
	assert_false(is_instance_valid(pickup), "RF-57")


func test_map_has_ammo_crates() -> void:
	var director: AmmoSpawnDirector = game.get_node("AmmoSpawnDirector")
	assert_eq((game.get_node("ZooLevel") as ZooLevel).get_ammo_spawns().size(), 15, "RF-59: 15 candidate points")
	assert_eq(director.active_count(), director.config.active_count)
