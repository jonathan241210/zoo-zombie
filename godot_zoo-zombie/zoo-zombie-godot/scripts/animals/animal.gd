class_name Animal
extends CharacterBody3D
## A zoo animal (spec 001 §5.3). Phase 3: wanders inside its enclosure and eats when fed.
## Hunger/weakness (phase 4) and escape/follow (phase 7) extend this state machine.

enum State { IDLE, WALK, EATING, DEAD }

signal state_changed(new_state: State)
signal fed

@export var config: AnimalConfig
## Feeder scene spawned for this animal (elevated for the giraffe, low for the elephant).
@export var feeder_scene: PackedScene
## Collision radius used to keep wander targets away from obstacles.
@export var body_radius: float = 0.8

## Max turn rate (rad/s). While facing away from the target the animal slows down
## (turns almost in place) instead of sliding sideways.
const TURN_SPEED := 1.6
const ARRIVE_DISTANCE := 0.6
const STUCK_SECONDS := 1.2
const STUCK_MIN_PROGRESS := 0.15
const MAX_STUCK_RETRIES := 3
const ANIM_BLEND := 0.3

var state: State = State.IDLE
var enclosure: Enclosure = null
var feeder: Feeder = null
var needs: AnimalNeeds

var _target := Vector3.ZERO
var _has_target := false
var _timer := 0.0
var _stuck_timer := 0.0
var _last_distance := INF
## Consecutive times the animal got stuck; after a few it rests before trying again.
var _stuck_count := 0
var _was_stuck := false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var health: HealthComponent = $HealthComponent
@onready var _animation: AnimationPlayer = find_children("*", "AnimationPlayer", true, false)[0]


func _ready() -> void:
	assert(config != null, "Animal needs an AnimalConfig")
	health.reset(config.max_health)
	health.died.connect(_on_health_depleted)
	needs = AnimalNeeds.new()
	needs.configure(config)
	for loop_name: StringName in [&"idle", &"walk", &"run", &"eat", &"weak"]:
		if _animation.has_animation(loop_name):
			_animation.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR
	GameManager.register_animal(config.animal_id)
	_enter_state(State.IDLE)
	EventBus.animal_registered.emit(self)


func _physics_process(delta: float) -> void:
	var hunger_damage := needs.tick(delta)
	if hunger_damage > 0.0:
		health.take_damage(hunger_damage, self)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	match state:
		State.IDLE:
			_stop()
			_timer -= delta
			if _timer <= 0.0:
				_pick_wander_target()
		State.WALK:
			if _move_to_target(delta, config.walk_speed):
				if _was_stuck and _stuck_count < MAX_STUCK_RETRIES:
					_pick_wander_target()  # blocked: try another direction right away
				else:
					_stuck_count = 0
					_enter_state(State.IDLE)
		State.EATING:
			if _has_target:
				if _move_to_target(delta, config.walk_speed):
					_has_target = false
					_play(&"eat")
			else:
				_stop()
				_timer -= delta
				if _timer <= 0.0:
					_enter_state(State.IDLE)
		State.DEAD:
			_stop()
	move_and_slide()


## Called by the EnclosureRegistry: places the animal inside and moves its feeder there.
func enter_enclosure(new_enclosure: Enclosure) -> void:
	enclosure = new_enclosure
	global_position = enclosure.random_interior_point(body_radius, null, [get_rid()]) + Vector3.UP * 0.2
	rotation.y = randf() * TAU
	if feeder == null and feeder_scene != null:
		feeder = feeder_scene.instantiate() as Feeder
		get_parent().add_child(feeder)
	if feeder != null:
		feeder.attach(self, enclosure)
	_enter_state(State.IDLE)


## True while the animal can receive food (contained and alive).
func can_be_fed() -> bool:
	return enclosure != null and state != State.DEAD


func can_receive_damage_from(source: Node) -> bool:
	if source is PlayerController and not config.player_damageable:
		return false
	return state != State.DEAD


## Feeding (RF-25): heal, notify, walk to the feeder and play the eat animation.
func feed() -> bool:
	if not can_be_fed():
		return false
	if health.current_health < health.max_health:
		health.heal(config.heal_per_feeding)
	needs.feed()
	if feeder != null and is_instance_valid(feeder):
		feeder.set_filled(true)
	fed.emit()
	EventBus.animal_fed.emit(config.animal_id)
	_enter_state(State.EATING)
	if feeder != null:
		_target = feeder.get_eat_position()
		_has_target = true
		_play(&"walk")
	else:
		_play(&"eat")
	return true


func _enter_state(new_state: State) -> void:
	state = new_state
	_stuck_timer = 0.0
	_last_distance = INF
	match state:
		State.IDLE:
			_timer = randf_range(config.idle_time_min, config.idle_time_max)
			_play(&"idle")
		State.WALK:
			_play(&"walk")
		State.EATING:
			_timer = config.eat_duration
		State.DEAD:
			_play(&"death")
	state_changed.emit(state)
	EventBus.animal_state_changed.emit(config.animal_id, state)


func _on_health_depleted() -> void:
	if state == State.DEAD:
		return
	_enter_state(State.DEAD)
	EventBus.animal_died.emit(config.animal_id, global_position)
	if feeder != null and is_instance_valid(feeder):
		feeder.queue_free()
	var despawn_delay := maxf(config.death_despawn_delay, 0.0)
	if _animation.has_animation(&"death"):
		despawn_delay = maxf(despawn_delay, _animation.get_animation(&"death").length)
	get_tree().create_timer(despawn_delay, false).timeout.connect(queue_free)


func _pick_wander_target() -> void:
	if enclosure == null:
		_timer = config.idle_time_min
		return
	_target = enclosure.random_interior_point(body_radius, global_position, [get_rid()])
	_has_target = true
	_enter_state(State.WALK)


## Steers toward _target; returns true on arrival or when stuck (gives up).
func _move_to_target(delta: float, speed: float) -> bool:
	var to_target := _target - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	_was_stuck = false
	if distance < ARRIVE_DISTANCE:
		_stop()
		return true
	var direction := to_target / distance
	# The model faces -Z (rotated in the scene), so yaw toward the movement direction.
	var target_yaw := atan2(-direction.x, -direction.z)
	var yaw_error := wrapf(target_yaw - rotation.y, -PI, PI)
	rotation.y += clampf(yaw_error, -TURN_SPEED * delta, TURN_SPEED * delta)
	# Move along the facing direction, slowing down while still turning toward the target.
	var facing := -global_basis.z
	var alignment := clampf(facing.dot(direction), 0.0, 1.0)
	var current_speed := speed * maxf(alignment * alignment, 0.15)
	velocity.x = facing.x * current_speed
	velocity.z = facing.z * current_speed
	_sync_animation_speed(current_speed, speed)
	_stuck_timer += delta
	if _stuck_timer >= STUCK_SECONDS:
		var progressed := _last_distance - distance
		_last_distance = distance
		_stuck_timer = 0.0
		if progressed < STUCK_MIN_PROGRESS * STUCK_SECONDS:
			_stop()
			_was_stuck = true
			_stuck_count += 1
			return true
	return false


func _stop() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_animation.speed_scale = 1.0


## Scales walk/run playback to the actual ground speed so the feet do not slide.
func _sync_animation_speed(current_speed: float, nominal_speed: float) -> void:
	var anim_speed := config.run_anim_speed if nominal_speed > config.walk_speed else config.walk_anim_speed
	_animation.speed_scale = clampf(current_speed / anim_speed, 0.3, 2.0)


func _play(animation_name: StringName) -> void:
	if _animation.has_animation(animation_name) and _animation.current_animation != animation_name:
		_animation.play(animation_name, ANIM_BLEND)
