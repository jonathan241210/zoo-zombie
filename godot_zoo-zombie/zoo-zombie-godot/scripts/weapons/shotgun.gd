class_name Shotgun
extends Node
## First-person hitscan shotgun (spec 001 RF-50 to RF-54).

signal fired
signal reloaded
signal hit_confirmed(target: Node)

@export var config: ShotgunConfig
@export var player: PlayerController
@export var carry: PlayerCarry
@export var camera: Camera3D
@export var view_model: Node3D

var ammo: AmmoState
var is_reloading: bool = false
var _next_fire_time: float = 0.0
var _reload_generation: int = 0
var _animation_player: AnimationPlayer


func _ready() -> void:
	assert(config != null and player != null and carry != null and camera != null)
	ammo = AmmoState.new(config)
	_animation_player = _find_animation_player(view_model)
	carry.state_changed.connect(_on_carry_state_changed)
	_publish_ammo()


func _process(_delta: float) -> void:
	if not player.input_enabled:
		return
	if Input.is_action_pressed(&"fire"):
		fire()
	if Input.is_action_just_pressed(&"reload"):
		reload()


func fire() -> bool:
	if not _can_use() or is_reloading or Time.get_ticks_msec() / 1000.0 < _next_fire_time:
		return false
	if not ammo.consume_shell():
		return false
	_next_fire_time = Time.get_ticks_msec() / 1000.0 + config.fire_interval
	_play_animation(&"shotgun_fire")
	_apply_recoil()
	_flash_muzzle()
	for pellet_index in config.pellets_per_shot:
		_fire_pellet()
	_publish_ammo()
	fired.emit()
	return true


func reload() -> bool:
	if not _can_use() or is_reloading or ammo.reserve <= 0 or ammo.magazine >= ammo.magazine_size:
		return false
	is_reloading = true
	_reload_generation += 1
	var generation := _reload_generation
	var tween := create_tween()
	tween.tween_property(view_model, "position:y", view_model.position.y + 0.12, config.reload_time * 0.35)
	tween.tween_property(view_model, "position:y", view_model.position.y, config.reload_time * 0.65)
	await tween.finished
	if generation != _reload_generation:
		return false
	ammo.reload()
	is_reloading = false
	_publish_ammo()
	reloaded.emit()
	return true


func cancel_reload() -> void:
	if is_reloading:
		_reload_generation += 1
		is_reloading = false


func _on_carry_state_changed(state: PlayerCarry.State) -> void:
	if state == PlayerCarry.State.CARRYING:
		cancel_reload()


func _can_use() -> bool:
	return is_instance_valid(player) and player.input_enabled and carry.can_use_weapons()


func _fire_pellet() -> void:
	var spread := deg_to_rad(config.spread_degrees)
	var direction := -camera.global_basis.z
	direction = (direction + camera.global_basis.x * randf_range(-spread, spread) \
		+ camera.global_basis.y * randf_range(-spread, spread)).normalized()
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,
		camera.global_position + direction * config.max_range)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = true
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var target := result["collider"] as Node
	var health := _find_health(target)
	if health != null:
		health.take_damage(config.damage_per_pellet, player)
		hit_confirmed.emit(target)
	_spawn_impact(result["position"], result["normal"])


func _find_health(target: Node) -> HealthComponent:
	var current: Node = target
	while current != null:
		if current is HealthComponent:
			return current as HealthComponent
		var component := current.get_node_or_null("HealthComponent") as HealthComponent
		if component != null:
			return component
		current = current.get_parent()
	return null


func _spawn_impact(point: Vector3, normal: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.48, 0.12)
	marker.material_override = material
	player.get_tree().current_scene.add_child(marker)
	marker.global_position = point + normal * 0.025
	var tween := marker.create_tween()
	tween.tween_property(marker, "scale", Vector3.ZERO, 0.22)
	tween.tween_callback(marker.queue_free)


func _apply_recoil() -> void:
	var kick := deg_to_rad(config.camera_recoil_degrees)
	player.head.rotation.x = clampf(player.head.rotation.x - kick, -deg_to_rad(player.config.pitch_limit_degrees),
		deg_to_rad(player.config.pitch_limit_degrees))
	var tween := create_tween()
	tween.tween_property(player.head, "rotation:x", player.head.rotation.x + kick * 0.7, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _flash_muzzle() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.66, 0.25)
	light.light_energy = 3.0
	light.omni_range = 3.0
	light.position = Vector3(0.0, 0.0, -0.65)
	camera.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.07)
	tween.tween_callback(light.queue_free)


func _play_animation(animation: StringName) -> void:
	if _animation_player != null and _animation_player.has_animation(animation):
		_animation_player.play(animation)


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	var players := root.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null


func _publish_ammo() -> void:
	EventBus.ammo_changed.emit(ammo.magazine, ammo.reserve)
