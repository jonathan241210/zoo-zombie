class_name WaveManager
extends Node
## Runs the three waves (spec 001 RF-70 to RF-76): drives the ZombieSpawner from the
## WaveSchedule with each wave's role ratio and multipliers, publishes wave events and
## the zombie counter, and declares victory when wave 3 ends with an animal alive.
## Its timers stop while the game is paused (normal process mode).

@export var config: WaveSetConfig
## Tests can disable the waves to set up their own zombies.
@export var enabled: bool = true

var schedule: WaveSchedule
var spawner: ZombieSpawner
var _breakers_spawned := 0
var _counter_timer := 0.0


func _ready() -> void:
	add_to_group(&"wave_manager")


func setup(zombie_spawner: ZombieSpawner) -> void:
	spawner = zombie_spawner
	schedule = WaveSchedule.new(config)
	schedule.phase_changed.connect(_on_phase_changed)
	if enabled:
		schedule.start()


func _process(delta: float) -> void:
	if not enabled or schedule == null or GameManager.state != GameManager.GameState.PLAYING:
		return
	var to_spawn := schedule.tick(delta, spawner.alive_count())
	for i in to_spawn:
		_spawn_wave_zombie()
	_counter_timer -= delta
	if _counter_timer <= 0.0:
		_counter_timer = 0.25
		EventBus.zombie_count_changed.emit(spawner.alive_count(), schedule.pending())


## Seconds left in the current phase (countdown, wave or break).
func time_left() -> float:
	return maxf(schedule.time_left, 0.0) if schedule != null else 0.0


func _spawn_wave_zombie() -> void:
	var wave := schedule.current_wave()
	# Deterministic share of breakers: keep breakers/spawned close to the wave ratio.
	var spawned := schedule.spawned_in_wave
	var role := Zombie.Role.HUNTER
	if _breakers_spawned < roundi(spawned * wave.breaker_ratio):
		role = Zombie.Role.BREAKER
		_breakers_spawned += 1
	spawner.spawn_wave_zombie(role, wave, config.min_spawn_distance)


func _on_phase_changed(phase: WaveSchedule.Phase, wave_index: int) -> void:
	match phase:
		WaveSchedule.Phase.WAVE:
			_breakers_spawned = 0
			EventBus.wave_started.emit(wave_index + 1)
		WaveSchedule.Phase.BREAK:
			EventBus.wave_break_started.emit(wave_index + 1)
		WaveSchedule.Phase.FINISHED:
			# RF-76: surviving wave 3 with at least one animal wins.
			if GameManager.living_animal_count() > 0:
				GameManager.finish_victory()
