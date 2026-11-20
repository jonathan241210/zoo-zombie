class_name FoodCrateDirector
extends Node
## Keeps a fixed food stock in the two warehouses (spec 001 RF-10, RF-13): fills its
## configured slots at match start and serializes replenishment through one global queue.

signal crate_spawned(crate: FoodCrate)

@export var config: FoodCrateConfig
@export var crate_scene: PackedScene

var _spawns: Array[Marker3D] = []
var _occupied: Dictionary = {}  # Marker3D -> FoodCrate
var _pending_respawns := 0
var _dropped_crates: Dictionary = {}  # FoodCrate -> true
var _carried_crates := 0
var _respawn_loop_running := false
var _supply_unavailable := false


func _ready() -> void:
	EventBus.player_carry_changed.connect(_on_player_carry_changed)


func setup(spawn_points: Array[Marker3D]) -> void:
	_spawns = spawn_points
	for i in mini(config.max_active, _spawns.size()):
		_spawn_one()
	_refresh_supply_state()


func active_count() -> int:
	return _occupied.size() + _dropped_crates.size() + _carried_crates


func register_dropped(crate: FoodCrate) -> void:
	_dropped_crates[crate] = true
	crate.picked_up.connect(_on_dropped_crate_picked_up)
	crate.tree_exiting.connect(_on_dropped_crate_removed.bind(crate), CONNECT_ONE_SHOT)
	_refresh_supply_state()


func pending_respawns() -> int:
	return _pending_respawns


func _spawn_one() -> FoodCrate:
	var free_points: Array[Marker3D] = []
	for point in _spawns:
		if not _occupied.has(point):
			free_points.append(point)
	if free_points.is_empty() or active_count() >= config.max_active:
		return null
	var point: Marker3D = free_points.pick_random()
	var crate := crate_scene.instantiate() as FoodCrate
	point.add_child(crate)
	crate.rotation.y = randf() * TAU
	_occupied[point] = crate
	crate.picked_up.connect(_on_crate_picked_up.bind(point))
	crate_spawned.emit(crate)
	_refresh_supply_state()
	return crate


func _on_crate_picked_up(_crate: FoodCrate, point: Marker3D) -> void:
	_occupied.erase(point)
	_pending_respawns += 1
	_refresh_supply_state()
	if not _respawn_loop_running:
		_run_respawn_queue()


func _on_dropped_crate_picked_up(crate: FoodCrate) -> void:
	_dropped_crates.erase(crate)
	_refresh_supply_state()


func _on_dropped_crate_removed(crate: FoodCrate) -> void:
	_dropped_crates.erase(crate)
	_refresh_supply_state()


func _on_player_carry_changed(is_carrying: bool) -> void:
	_carried_crates = 1 if is_carrying else 0
	_refresh_supply_state()


func _run_respawn_queue() -> void:
	_respawn_loop_running = true
	while _pending_respawns > 0:
		# process_always = false: the global cooldown stops while the game is paused.
		var timer := get_tree().create_timer(maxf(config.respawn_delay, 0.01), false)
		await timer.timeout
		if not is_inside_tree():
			return
		if _spawn_one() != null:
			_pending_respawns -= 1
	_respawn_loop_running = false


func _refresh_supply_state() -> void:
	var unavailable := active_count() == 0
	if unavailable == _supply_unavailable:
		return
	_supply_unavailable = unavailable
	if unavailable:
		EventBus.food_supply_depleted.emit()
	else:
		EventBus.food_supply_restored.emit()
