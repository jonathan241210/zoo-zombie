extends Node
## Owns the match lifecycle: state, survival time, statistics, living animals and restart.
## Victory is triggered by the WaveManager (via finish_victory); defeat happens here when
## every registered animal has died.

enum GameState { MENU, PLAYING, PAUSED, WON, LOST }

signal state_changed(new_state: GameState)

var state: GameState = GameState.MENU
var survival_time: float = 0.0
var stats: Dictionary = {}

var _living_animals: Dictionary = {}  # StringName -> true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.animal_died.connect(_on_animal_died)
	EventBus.animal_fed.connect(_on_animal_fed)
	EventBus.animal_recaptured.connect(_on_animal_recaptured)
	EventBus.enclosure_destroyed.connect(_on_enclosure_destroyed)
	EventBus.zombie_killed.connect(_on_zombie_killed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.player_died.connect(_on_player_died)
	reset_stats()


func _process(delta: float) -> void:
	if state == GameState.PLAYING:
		survival_time += delta


## Starts a fresh match. Call from the root game scene once it is ready.
func start_match() -> void:
	survival_time = 0.0
	_living_animals.clear()
	reset_stats()
	_set_state(GameState.PLAYING)


func reset_stats() -> void:
	stats = {
		"coins": 0,
		"zombies_killed": 0,
		"feedings": {},  # animal_id -> count
		"enclosures_destroyed": 0,
		"recaptures": 0,
		"player_deaths": 0,
		"animals_lost": [],
		"survival_time": 0.0,
	}


## Animals register themselves when they spawn so defeat can be detected.
func register_animal(animal_id: StringName) -> void:
	_living_animals[animal_id] = true


func living_animal_count() -> int:
	return _living_animals.size()


func set_paused(paused: bool) -> void:
	if state != GameState.PLAYING and state != GameState.PAUSED:
		return
	get_tree().paused = paused
	_set_state(GameState.PAUSED if paused else GameState.PLAYING)


func finish_victory() -> void:
	if state != GameState.PLAYING:
		return
	_set_state(GameState.WON)
	EventBus.game_won.emit(get_final_stats())


func get_final_stats() -> Dictionary:
	var final := stats.duplicate(true)
	final["survival_time"] = survival_time
	final["living_animals"] = _living_animals.keys()
	return final


func restart_match() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _set_state(new_state: GameState) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func _on_animal_died(animal_id: StringName, _position: Vector3) -> void:
	_living_animals.erase(animal_id)
	(stats["animals_lost"] as Array).append(animal_id)
	if state == GameState.PLAYING and _living_animals.is_empty():
		call_deferred("_finish_loss")


func _finish_loss() -> void:
	if state != GameState.PLAYING or not _living_animals.is_empty():
		return
	_set_state(GameState.LOST)
	EventBus.game_lost.emit(get_final_stats())


func _on_animal_fed(animal_id: StringName) -> void:
	var feedings: Dictionary = stats["feedings"]
	feedings[animal_id] = int(feedings.get(animal_id, 0)) + 1


func _on_animal_recaptured(_animal_id: StringName, _enclosure: Node3D) -> void:
	stats["recaptures"] += 1


func _on_enclosure_destroyed(_enclosure: Node3D) -> void:
	stats["enclosures_destroyed"] += 1


func _on_zombie_killed(_zombie: Node3D) -> void:
	stats["zombies_killed"] += 1


func _on_score_changed(coins: int) -> void:
	stats["coins"] = coins


func _on_player_died() -> void:
	stats["player_deaths"] += 1
