class_name Animal
extends CharacterBody3D
## A zoo animal (spec 001 §5.3). Wanders inside its enclosure, eats when fed and loses
## health from hunger. Weakness (RF-27) is a modifier on top of the movement states:
## below the health threshold the animal plays `weak` instead of `idle` and moves slower.
## Phase 7: when its enclosure is destroyed it ESCAPES through the broken fence, then
## roams free (LOOSE), FLEES from nearby zombies until it gets TIRED (stamina), and
## FOLLOWS the player who carries food (RF-40 to RF-45). Free movement uses the navmesh.

enum State { IDLE, WALK, EATING, DEAD, ESCAPING, LOOSE, FLEEING, TIRED, FOLLOWING }

signal state_changed(new_state: State)
signal fed
signal weak_changed(is_weak: bool)

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
## Seconds between decisions while escaped (lure, threats, flee target).
const THINK_INTERVAL := 0.25
## How far ahead (m) a fleeing animal aims when running away.
const FLEE_LOOKAHEAD := 10.0
## Escaping gives up after this long (e.g. sliding along an obstacle) and roams free.
const ESCAPE_MAX_SECONDS := 3.0

var state: State = State.IDLE
var enclosure: Enclosure = null
var feeder: Feeder = null
var needs: AnimalNeeds
## True while health is below config.weak_threshold (RF-27).
var is_weak := false
var stamina: Stamina

## True between escaping and being recaptured.
var _escaped := false
var _think_timer := 0.0
var _goal := Vector3.ZERO
var _nav_agent: NavigationAgent3D

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
	health.health_changed.connect(_on_health_changed)
	needs = AnimalNeeds.new()
	needs.configure(config)
	stamina = Stamina.from_config(config)
	_nav_agent = NavigationAgent3D.new()
	_nav_agent.radius = body_radius
	_nav_agent.height = 3.0
	_nav_agent.path_desired_distance = 1.0
	_nav_agent.target_desired_distance = 1.0
	add_child(_nav_agent)
	add_to_group(&"animals")
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
	if _escaped and state != State.DEAD:
		_process_escaped(delta)
		move_and_slide()
		return
	match state:
		State.IDLE:
			_stop()
			_timer -= delta
			if _timer <= 0.0:
				_pick_wander_target()
		State.WALK:
			if _move_to_target(delta, get_move_speed()):
				if _was_stuck and _stuck_count < MAX_STUCK_RETRIES:
					_pick_wander_target()  # blocked: try another direction right away
				else:
					_stuck_count = 0
					_enter_state(State.IDLE)
		State.EATING:
			if _has_target:
				if _move_to_target(delta, get_move_speed()):
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
## On recapture (`near` given) it stands inside next to where it reached the fence.
func enter_enclosure(new_enclosure: Enclosure, near: Variant = null) -> void:
	enclosure = new_enclosure
	_escaped = false
	global_position = _interior_point(near) + Vector3.UP * 0.2
	if not near is Vector3:
		rotation.y = randf() * TAU
	if feeder == null and feeder_scene != null:
		feeder = feeder_scene.instantiate() as Feeder
		get_parent().add_child(feeder)
	if feeder != null:
		feeder.attach(self, enclosure)
	_enter_state(State.IDLE)


## True while the animal can receive food (contained and alive). RF-26.
func can_be_fed() -> bool:
	return enclosure != null and state != State.DEAD


## True while out of any enclosure (escaped and not yet recaptured).
func is_escaped() -> bool:
	return _escaped and state != State.DEAD


## Translation key of the status shown on the HUD card and end screen (RF-101, RF-105).
func get_status_key() -> String:
	match state:
		State.DEAD:
			return "ANIMAL_STATUS_DEAD"
		State.TIRED:
			return "ANIMAL_STATUS_TIRED"
		State.FOLLOWING:
			return "ANIMAL_STATUS_FOLLOWING"
	if _escaped:
		return "ANIMAL_STATUS_ESCAPED"
	if is_weak:
		return "ANIMAL_STATUS_WEAK"
	return "ANIMAL_STATUS_CONTAINED"


## RF-33: the enclosure was destroyed. The feeder is unusable until a new enclosure is
## assigned, and the animal runs out through the broken fence.
func escape(from: Enclosure) -> void:
	if state == State.DEAD or _escaped:
		return
	enclosure = null
	_escaped = true
	if feeder != null and is_instance_valid(feeder):
		feeder.detach()
	var away := global_position - from.global_position
	away.y = 0.0
	if away.length() < 0.1:
		away = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	away = away.normalized()
	var reach := from.distance_to_outline(global_position + away * 200.0)
	_target = global_position + away * (200.0 - reach + Enclosure.INTERIOR_MARGIN + config.exit_distance)
	_target.y = global_position.y
	_has_target = true
	_enter_state(State.ESCAPING)
	_timer = ESCAPE_MAX_SECONDS
	EventBus.animal_escaped.emit(config.animal_id)


## Walking speed, reduced while weak (RF-27).
func get_move_speed() -> float:
	return config.walk_speed * (config.weak_speed_multiplier if is_weak else 1.0)


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
	EventBus.coins_earned.emit(config.feed_score)
	_enter_state(State.EATING)
	if feeder != null:
		_target = feeder.get_eat_position()
		_has_target = true
		_play(&"walk")
	else:
		_play(&"eat")
	return true


func _enter_state(new_state: State) -> void:
	if state == new_state and new_state in [State.LOOSE, State.FLEEING, State.TIRED, State.FOLLOWING]:
		return
	state = new_state
	_stuck_timer = 0.0
	_last_distance = INF
	match state:
		State.IDLE:
			_timer = randf_range(config.idle_time_min, config.idle_time_max)
			_play(_idle_animation())
		State.WALK:
			_play(&"walk")
		State.EATING:
			_timer = config.eat_duration
		State.DEAD:
			_play(&"death")
	state_changed.emit(state)
	EventBus.animal_state_changed.emit(config.animal_id, state)


func _on_health_changed(current: float, maximum: float) -> void:
	var weak_now := current > 0.0 and maximum > 0.0 and current / maximum < config.weak_threshold
	if weak_now == is_weak:
		return
	is_weak = weak_now
	weak_changed.emit(is_weak)
	EventBus.animal_weak_changed.emit(config.animal_id, is_weak)
	if state == State.IDLE:
		_play(_idle_animation())


func _idle_animation() -> StringName:
	return &"weak" if is_weak and _animation.has_animation(&"weak") else &"idle"


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


func _process_escaped(delta: float) -> void:
	var running := state == State.ESCAPING or state == State.FLEEING
	stamina.tick(delta, running and stamina.can_run())
	_think_timer -= delta
	var think := _think_timer <= 0.0
	if think:
		_think_timer = THINK_INTERVAL
	if state == State.ESCAPING:
		var speed := _escape_speed()
		_play(&"run" if speed > config.walk_speed else &"walk")
		_timer -= delta
		# Straight out: the destroyed fence no longer collides.
		if _move_to_target(delta, speed) or _timer <= 0.0:
			_enter_state(State.LOOSE)
		return
	if think:
		_choose_escaped_state()
	match state:
		State.FOLLOWING:
			var player := _player()
			if player != null and _flat_distance(player.global_position) > config.follow_distance:
				_navigate(player.global_position, _scaled(config.walk_speed), think, delta)
				_play(&"walk")
			else:
				_stop()
				_play(_idle_animation())
		State.FLEEING, State.TIRED:
			var speed := _escape_speed()
			_navigate(_goal, speed, think, delta)
			_play(&"run" if speed > config.walk_speed else &"walk")
		_:
			_stop()
			_play(_idle_animation())


## RF-44 lure has priority over fleeing (a following animal does not flee); otherwise it
## runs from the nearest zombie inside flee_radius, or rests.
func _choose_escaped_state() -> void:
	var player := _player()
	if player != null and player.is_carrying and not player.health.is_dead:
		var distance := _flat_distance(player.global_position)
		var keeps_following := state == State.FOLLOWING and distance <= config.follow_max_radius
		if keeps_following or distance <= config.lure_radius:
			_enter_state(State.FOLLOWING)
			return
	var threat := _nearest_threat()
	if threat != null:
		var away := global_position - threat.global_position
		away.y = 0.0
		_goal = global_position + away.normalized() * FLEE_LOOKAHEAD
		_enter_state(State.TIRED if stamina.is_tired else State.FLEEING)
		return
	_enter_state(State.LOOSE)


## Speed while escaping or fleeing: run, or the slow tired walk (RF-42).
func _escape_speed() -> float:
	return _scaled(config.tired_speed if stamina.is_tired else config.run_speed)


func _scaled(speed: float) -> float:
	return speed * (config.weak_speed_multiplier if is_weak else 1.0)


## Follows the navmesh toward `goal` (around rocks, fences and buildings).
func _navigate(goal: Vector3, speed: float, think: bool, delta: float) -> void:
	if think:
		_nav_agent.target_position = goal
	var next := _nav_agent.get_next_path_position()
	if _nav_agent.is_navigation_finished() or _flat_distance(next) < 0.2:
		next = goal
	_target = next
	_move_to_target(delta, speed)


func _nearest_threat() -> Node3D:
	var best: Node3D = null
	var best_distance := config.flee_radius
	for node in get_tree().get_nodes_in_group(&"zombies"):
		var zombie := node as Node3D
		var distance := _flat_distance(zombie.global_position)
		if distance < best_distance:
			best_distance = distance
			best = zombie
	return best


func _player() -> PlayerController:
	return get_tree().get_first_node_in_group(&"player") as PlayerController


func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


## Interior point; the one closest to `near` (of a few candidates) when given.
func _interior_point(near: Variant) -> Vector3:
	if not near is Vector3:
		return enclosure.random_interior_point(body_radius, null, [get_rid()])
	var best := enclosure.random_interior_point(body_radius, null, [get_rid()])
	for i in 7:
		var candidate := enclosure.random_interior_point(body_radius, null, [get_rid()])
		if candidate.distance_squared_to(near) < best.distance_squared_to(near):
			best = candidate
	return best
