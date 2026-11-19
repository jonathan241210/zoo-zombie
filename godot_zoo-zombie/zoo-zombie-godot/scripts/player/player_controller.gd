class_name PlayerController
extends CharacterBody3D
## First-person movement and look (spec 001 RF-01, spec 005): walk, sprint, jump, mouse and
## gamepad look. Carrying speed (RF-05) is driven by `is_carrying`, set by PlayerCarry.

@export var config: PlayerConfig

## Set by PlayerCarry (phase 3). While true the player moves at carry_speed.
var is_carrying: bool = false
## Disabled while dead or in menus.
var input_enabled: bool = true

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _death_tween: Tween

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	assert(config != null, "PlayerController needs a PlayerConfig")
	add_to_group(&"player")
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
	elif (event is InputEventMouseButton and event.is_pressed()
		and not _is_mouse_captured() and not get_tree().paused):
		set_mouse_captured(true)


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = config.coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
		velocity.y -= config.gravity * delta
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	var move_input := Vector2.ZERO
	if input_enabled:
		_apply_stick_look(delta)
		move_input = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		if Input.is_action_just_pressed(&"jump"):
			_jump_buffer_timer = config.jump_buffer_time

	# A buffered press plus coyote time allows the jump; both timers are spent so there is
	# no double jump (spec 005 RF-05).
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and can_jump():
		velocity.y = jump_velocity(config.jump_height, config.gravity)
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	var direction := transform.basis * Vector3(move_input.x, 0.0, move_input.y)
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var target := direction * get_target_speed(move_input)
	var rate := config.acceleration if direction != Vector3.ZERO else config.deceleration
	var weight := 1.0 - exp(-rate * delta)
	# Airborne: the player keeps momentum and only corrects it partially (RF-06, RF-15).
	if not on_floor:
		weight *= config.air_control
	velocity.x = lerpf(velocity.x, target.x, weight)
	velocity.z = lerpf(velocity.z, target.z, weight)
	move_and_slide()


## Launch speed needed to reach `height` meters under `gravity` (spec 005 RF-02).
static func jump_velocity(height: float, gravity: float) -> float:
	return sqrt(2.0 * gravity * height)


## Jumping is blocked while carrying a crate or when input is disabled (RF-03).
func can_jump() -> bool:
	return input_enabled and not is_carrying


## Speed for the current state: carrying > sprinting > walking. Sprinting needs Shift held
## and forward input, unless backward sprint is allowed (RF-10, RF-12, RF-13).
func get_target_speed(move_input: Vector2) -> float:
	if is_carrying:
		return config.carry_speed
	var moving_forward := move_input.y < -0.1
	var can_sprint := moving_forward or (config.allow_backward_sprint and move_input != Vector2.ZERO)
	if Input.is_action_pressed(&"sprint") and can_sprint:
		return config.sprint_speed
	return config.walk_speed


## Places the player at a spawn point with full health (used at start and on respawn).
func respawn_at(spawn: Transform3D) -> void:
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	global_transform = Transform3D(Basis(Vector3.UP, spawn.basis.get_euler().y), spawn.origin)
	head.rotation = Vector3.ZERO
	head.position.y = config.eye_height
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
	# The camera drops to the ground and rolls to the side (RF-80).
	_death_tween = create_tween().set_parallel()
	_death_tween.tween_property(head, "position:y", 0.35, 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_death_tween.tween_property(head, "rotation:z", deg_to_rad(70.0), 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	EventBus.player_died.emit()
