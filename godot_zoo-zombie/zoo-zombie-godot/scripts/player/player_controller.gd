class_name PlayerController
extends CharacterBody3D
## First-person movement and look (spec 001 RF-01): walk, sprint, no jump, mouse and
## gamepad look. Carrying speed (RF-05) is driven by `is_carrying`, set by PlayerCarry.

@export var config: PlayerConfig

## Set by PlayerCarry (phase 3). While true the player moves at carry_speed.
var is_carrying: bool = false
## Disabled while dead or in menus.
var input_enabled: bool = true

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	assert(config != null, "PlayerController needs a PlayerConfig")
	health.reset(config.max_health)
	health.died.connect(_on_died)
	head.position.y = config.eye_height
	camera.fov = config.fov
	set_mouse_captured(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _is_mouse_captured() and input_enabled:
		var motion := event as InputEventMouseMotion
		_apply_look(-motion.relative.x * config.mouse_sensitivity,
			-motion.relative.y * config.mouse_sensitivity)
	elif event.is_action_pressed("pause"):
		# Temporary until the pause menu exists (spec 002): release/recapture the mouse.
		set_mouse_captured(not _is_mouse_captured())
	elif event is InputEventMouseButton and event.is_pressed() and not _is_mouse_captured():
		set_mouse_captured(true)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var move_input := Vector2.ZERO
	if input_enabled:
		_apply_stick_look(delta)
		move_input = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")

	var direction := transform.basis * Vector3(move_input.x, 0.0, move_input.y)
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var target := direction * get_target_speed(move_input)
	var rate := config.acceleration if direction != Vector3.ZERO else config.deceleration
	var weight := 1.0 - exp(-rate * delta)
	velocity.x = lerpf(velocity.x, target.x, weight)
	velocity.z = lerpf(velocity.z, target.z, weight)
	move_and_slide()


## Speed for the current state: carrying > sprinting (forward only) > walking.
func get_target_speed(move_input: Vector2) -> float:
	if is_carrying:
		return config.carry_speed
	if Input.is_action_pressed(&"sprint") and move_input.y < -0.1:
		return config.sprint_speed
	return config.walk_speed


## Places the player at a spawn point with full health (used at start and on respawn).
func respawn_at(spawn: Transform3D) -> void:
	global_transform = Transform3D(Basis(Vector3.UP, spawn.basis.get_euler().y), spawn.origin)
	head.rotation.x = 0.0
	velocity = Vector3.ZERO
	health.reset(config.max_health)
	input_enabled = true


func set_mouse_captured(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func _is_mouse_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func _apply_stick_look(delta: float) -> void:
	var look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down",
		config.stick_deadzone)
	if look != Vector2.ZERO:
		_apply_look(-look.x * config.stick_sensitivity * delta,
			-look.y * config.stick_sensitivity * delta)


func _apply_look(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	var limit := deg_to_rad(config.pitch_limit_degrees)
	head.rotation.x = clampf(head.rotation.x + pitch, -limit, limit)


func _on_died() -> void:
	input_enabled = false
	velocity = Vector3.ZERO
	EventBus.player_died.emit()
