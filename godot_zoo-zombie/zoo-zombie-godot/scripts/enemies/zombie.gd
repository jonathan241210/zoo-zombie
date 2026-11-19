class_name Zombie
extends CharacterBody3D
## Zombie (spec 001 RF-60 to RF-68): detects the player by radius and line of sight,
## follows the navmesh, attacks in melee (also while the player carries a crate),
## staggers when hit, can be pushed back by the axe and leaves a body that disappears.
## Its role decides the target through ZombieTargetSelector: hunters chase the player,
## breakers hit the nearest occupied enclosure; any zombie attacks an escaped animal.

enum State { IDLE, CHASE, ATTACK, HIT, DEAD }
enum Role { HUNTER, BREAKER }

signal state_changed(new_state: State)

## Physics layers.
const WORLD_MASK := 1
## Decay rate of the knockback velocity (1/s). Distance pushed = initial speed / rate.
const KNOCKBACK_DECAY := 8.0
const ANIM_BLEND := 0.2
const EYE_HEIGHT := 1.6

@export var config: ZombieConfig
@export var ammo_pickup_scene: PackedScene

## Wave multipliers (phase 8); 1.0 = base values from the config.
var health_multiplier := 1.0
var speed_multiplier := 1.0
var damage_multiplier := 1.0

var state: State = State.IDLE
var role: Role = Role.HUNTER
## A breaker that was hurt or approached by the player hunts the player (RF-61).
var aggro_player := false
## Current target: the player, an escaped animal or an enclosure.
var target: Node3D = null
var target_kind: ZombieTargetSelector.Kind = ZombieTargetSelector.Kind.PLAYER
## Zombies spawned during a wave already know where their target is (RF-63).
var alerted := false
## Chooses the target; null keeps the one given in setup() (tests).
var selector: ZombieTargetSelector = null

var _attack_point := Vector3.ZERO

var _think_timer := 0.0
var _attack_cooldown := 0.0
var _attack_hit_timer := 0.0
var _attack_pending := false
var _hit_timer := 0.0
var _knockback := Vector3.ZERO
var _safe_velocity := Vector3.ZERO
var _has_line_of_sight := false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var health: HealthComponent = $HealthComponent
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _animation: AnimationPlayer = find_children("*", "AnimationPlayer", true, false)[0]


func _ready() -> void:
	assert(config != null, "Zombie needs a ZombieConfig")
	health.reset(config.max_health * health_multiplier)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	for loop_name: StringName in [&"idle", &"walk", &"run"]:
		if _animation.has_animation(loop_name):
			_animation.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR
	nav_agent.velocity_computed.connect(func(safe: Vector3) -> void: _safe_velocity = safe)
	# Spread the "think" work of many zombies over different frames.
	_think_timer = randf() * config.think_interval
	add_to_group(&"zombies")
	_enter_state(State.IDLE)


## Called by the spawner before or right after adding the zombie to the tree.
func setup(new_target: Node3D, is_alerted: bool) -> void:
	target = new_target
	target_kind = ZombieTargetSelector.Kind.PLAYER
	alerted = is_alerted


## Gives the zombie its role and target selector (spawner).
func set_ai(target_selector: ZombieTargetSelector, new_role: Role) -> void:
	selector = target_selector
	role = new_role


## Pushes the zombie (axe, RF-5A). `push` is the total displacement in meters.
func apply_knockback(push: Vector3) -> void:
	if state == State.DEAD:
		return
	push.y = 0.0
	_knockback = push * KNOCKBACK_DECAY


func is_dead() -> bool:
	return state == State.DEAD


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	_think_timer -= delta
	var think := _think_timer <= 0.0
	if think:
		_think_timer = config.think_interval
	match state:
		State.IDLE:
			_stop()
			if think:
				_retarget()
				if _target_alive() and (target_kind != ZombieTargetSelector.Kind.PLAYER or alerted or _can_detect()):
					_enter_state(State.CHASE)
		State.CHASE:
			_process_chase(delta, think)
		State.ATTACK:
			_process_attack(delta, think)
		State.HIT:
			_stop()
			_hit_timer -= delta
			if _hit_timer <= 0.0:
				_enter_state(State.CHASE if _target_alive() else State.IDLE)
		State.DEAD:
			_stop()
	if _knockback.length_squared() > 0.0001:
		velocity.x += _knockback.x
		velocity.z += _knockback.z
		_knockback *= exp(-KNOCKBACK_DECAY * delta)
	move_and_slide()


func _process_chase(delta: float, think: bool) -> void:
	if think:
		_retarget()
	if not _target_alive():
		_enter_state(State.IDLE)
		return
	var goal := _goal_position()
	var distance := _flat_distance_to(goal)
	if distance <= config.attack_range:
		_enter_state(State.ATTACK)
		return
	if think:
		nav_agent.target_position = goal
		_has_line_of_sight = target_kind != ZombieTargetSelector.Kind.ENCLOSURE and _line_of_sight_to(target)
	var speed := (config.run_speed if _has_line_of_sight else config.walk_speed) * speed_multiplier
	var next := nav_agent.get_next_path_position()
	var to_next := next - global_position
	to_next.y = 0.0
	if nav_agent.is_navigation_finished() or to_next.length() < 0.05:
		# No path (e.g. off the navmesh): head straight for the target.
		to_next = goal - global_position
		to_next.y = 0.0
	var direction := to_next.normalized()
	var desired := direction * speed
	if nav_agent.avoidance_enabled:
		nav_agent.velocity = desired
		desired = Vector3(_safe_velocity.x, 0.0, _safe_velocity.z)
	velocity.x = desired.x
	velocity.z = desired.z
	_turn_towards(direction, delta)
	_play(&"run", Vector2(velocity.x, velocity.z).length() / config.run_anim_speed)


func _process_attack(delta: float, think: bool) -> void:
	_stop()
	if think:
		_retarget()  # e.g. a breaker that was hurt switches to the player
		if state != State.ATTACK:
			return
	if not _target_alive():
		_attack_pending = false
		_enter_state(State.IDLE)
		return
	# Face what is being hit (the fence centre for enclosures), but measure the reach to
	# the goal (the attack point outside the fence for enclosures).
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.01:
		_turn_towards(to_target.normalized(), delta)
	var distance := _flat_distance_to(_goal_position())
	_attack_cooldown -= delta
	if _attack_pending:
		_attack_hit_timer -= delta
		if _attack_hit_timer <= 0.0:
			_attack_pending = false
			# The blow lands only if the target is still in reach (it can dodge).
			if distance <= config.attack_range * 1.25:
				_hit_target()
	elif distance > config.attack_range * 1.3:
		_enter_state(State.CHASE)
	elif _attack_cooldown <= 0.0:
		_attack_pending = true
		_attack_hit_timer = config.attack_hit_delay
		_attack_cooldown = config.attack_interval
		_play(&"attack", 1.0, true)


func _hit_target() -> void:
	var target_health := target.get_node_or_null("HealthComponent") as HealthComponent
	if target_health == null:
		return
	var damage := config.damage_to_player
	match target_kind:
		ZombieTargetSelector.Kind.ANIMAL:
			damage = config.damage_to_animal
		ZombieTargetSelector.Kind.ENCLOSURE:
			damage = config.damage_to_enclosure
	target_health.take_damage(damage * damage_multiplier, self)


## Asks the selector for the current target (each think tick).
func _retarget() -> void:
	if selector == null:
		return
	var choice := selector.choose(self)
	var node := choice["node"] as Node3D
	if node == target and choice["kind"] == target_kind:
		return
	target = node
	target_kind = choice["kind"]
	if target_kind == ZombieTargetSelector.Kind.ENCLOSURE:
		_attack_point = (target as Enclosure).nearest_attack_point(global_position)
		alerted = true
	if state == State.ATTACK:
		_attack_pending = false
		_enter_state(State.CHASE)


## Where the zombie walks to: the attack point outside the fence for enclosures.
func _goal_position() -> Vector3:
	if target_kind == ZombieTargetSelector.Kind.ENCLOSURE:
		return _attack_point
	return target.global_position


func _enter_state(new_state: State) -> void:
	state = new_state
	match state:
		State.IDLE:
			_play(&"idle")
		State.CHASE:
			_has_line_of_sight = _target_alive() and _line_of_sight_to(target)
			if _target_alive():
				nav_agent.target_position = target.global_position
		State.ATTACK:
			_attack_cooldown = 0.0
			_attack_pending = false
		State.HIT:
			_hit_timer = config.hit_stun_time
			_attack_pending = false
			_play(&"hit", 1.6, true)
		State.DEAD:
			_play(&"death", 1.0, true)
	state_changed.emit(state)


func _on_damaged(_amount: float, source: Node) -> void:
	if state == State.DEAD or health.is_dead:
		return
	# Being hurt by the player makes a breaker hunt the player (RF-61).
	if source is PlayerController:
		aggro_player = true
	if source is Node3D and target == null:
		target = source as Node3D
	alerted = true
	_enter_state(State.HIT)


func _on_died() -> void:
	if state == State.DEAD:
		return
	_enter_state(State.DEAD)
	remove_from_group(&"zombies")
	# The body stays on the ground but no longer blocks the player or bullets.
	collision_layer = 0
	collision_mask = WORLD_MASK
	_knockback = Vector3.ZERO
	EventBus.zombie_killed.emit(self)
	_maybe_drop_ammo()
	get_tree().create_timer(config.corpse_lifetime, false).timeout.connect(queue_free)


## RF-55: random chance to leave a box of shells that expires (RF-57).
func _maybe_drop_ammo() -> void:
	if ammo_pickup_scene == null or randf() >= config.ammo_drop_chance:
		return
	var pickup := ammo_pickup_scene.instantiate() as AmmoPickup
	pickup.configure(config.ammo_drop_amount, config.ammo_drop_lifetime)
	# Deferred (we are inside a physics callback); the scene may be gone by then.
	_place_drop.call_deferred(pickup, get_parent(), global_position)


## Untyped: `parent` may already be freed, and a freed object cannot be passed as Node.
static func _place_drop(pickup: Variant, parent: Variant, at: Vector3) -> void:
	if not is_instance_valid(pickup):
		return
	if not is_instance_valid(parent) or not (parent as Node).is_inside_tree():
		(pickup as Node).free()
		return
	(parent as Node).add_child(pickup)
	(pickup as Node3D).global_position = at


func _target_alive() -> bool:
	if not is_instance_valid(target):
		return false
	if target is Enclosure:
		return (target as Enclosure).can_be_attacked()
	if target is Animal and not (target as Animal).is_escaped():
		return false  # recaptured or dead
	var target_health := target.get_node_or_null("HealthComponent") as HealthComponent
	return target_health == null or not target_health.is_dead


## RF-63: inside the detection radius and visible.
func _can_detect() -> bool:
	return _flat_distance_to(target.global_position) <= config.detection_radius and _line_of_sight_to(target)


func _line_of_sight_to(node: Node3D) -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * EYE_HEIGHT
	var to := node.global_position + Vector3.UP * EYE_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK)
	query.exclude = [get_rid()]
	return space.intersect_ray(query).is_empty()


func _flat_distance_to(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


func _turn_towards(direction: Vector3, delta: float) -> void:
	# The model faces -Z, so yaw toward the movement direction.
	var target_yaw := atan2(-direction.x, -direction.z)
	var step := deg_to_rad(config.turn_speed_degrees) * delta
	rotation.y += clampf(wrapf(target_yaw - rotation.y, -PI, PI), -step, step)


func _stop() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if nav_agent != null and nav_agent.avoidance_enabled:
		nav_agent.velocity = Vector3.ZERO


func _play(animation_name: StringName, speed: float = 1.0, restart: bool = false) -> void:
	if not _animation.has_animation(animation_name):
		return
	_animation.speed_scale = clampf(speed, 0.3, 2.5)
	if restart and _animation.current_animation == animation_name:
		_animation.seek(0.0, true)
	elif _animation.current_animation != animation_name:
		_animation.play(animation_name, ANIM_BLEND)
