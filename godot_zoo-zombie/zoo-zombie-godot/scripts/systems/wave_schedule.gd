class_name WaveSchedule
extends RefCounted
## Pure wave timeline (spec 001 RF-70 to RF-73): countdown -> wave 1 -> break -> wave 2
## -> break -> wave 3 -> finished. A wave ends when its time runs out; while it lasts a
## zombie is due every spawn_interval (the first one right away) until the wave total is
## reached, never above max_alive. Breaks spawn nothing.

enum Phase { COUNTDOWN, WAVE, BREAK, FINISHED }

signal phase_changed(phase: Phase, wave_index: int)

var config: WaveSetConfig
var phase: Phase = Phase.COUNTDOWN
## 0-based index of the current (or next, during countdown/break) wave.
var wave_index := 0
var time_left := 0.0
var spawned_in_wave := 0
var _spawn_timer := 0.0


func _init(wave_set: WaveSetConfig) -> void:
	config = wave_set


func start() -> void:
	wave_index = 0
	if config.initial_countdown > 0.0:
		_set_phase(Phase.COUNTDOWN, config.initial_countdown)
	else:
		_start_wave(0)


## Advances time. Returns how many zombies should spawn now given `alive` zombies.
func tick(delta: float, alive: int) -> int:
	if phase == Phase.FINISHED:
		return 0
	time_left -= delta
	var to_spawn := 0
	if phase == Phase.WAVE:
		_spawn_timer -= delta
		var wave := current_wave()
		if _spawn_timer <= 0.0 and spawned_in_wave < wave.total_zombies and alive < wave.max_alive:
			to_spawn = 1
			spawned_in_wave += 1
			_spawn_timer = wave.spawn_interval
	if time_left <= 0.0:
		_advance()
	return to_spawn


func current_wave() -> WaveConfig:
	return config.waves[clampi(wave_index, 0, config.waves.size() - 1)]


func wave_count() -> int:
	return config.waves.size()


## Zombies of the current wave still to appear (0 outside a wave). RF-10A.
func pending() -> int:
	return maxi(current_wave().total_zombies - spawned_in_wave, 0) if phase == Phase.WAVE else 0


func is_last_wave() -> bool:
	return wave_index >= config.waves.size() - 1


func _advance() -> void:
	match phase:
		Phase.COUNTDOWN:
			_start_wave(0)
		Phase.WAVE:
			if is_last_wave():
				_set_phase(Phase.FINISHED, 0.0)
			else:
				wave_index += 1
				_set_phase(Phase.BREAK, config.break_duration)
		Phase.BREAK:
			_start_wave(wave_index)


func _start_wave(index: int) -> void:
	wave_index = index
	spawned_in_wave = 0
	_spawn_timer = 0.0
	_set_phase(Phase.WAVE, current_wave().duration)


func _set_phase(new_phase: Phase, seconds: float) -> void:
	phase = new_phase
	time_left = seconds
	phase_changed.emit(phase, wave_index)
