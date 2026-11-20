extends GutTest
## WaveSchedule: countdown -> wave -> break -> ... -> finished (spec 001 RF-70 to RF-73).


func _wave(duration: float, total: int, interval: float, max_alive: int) -> WaveConfig:
	var wave := WaveConfig.new()
	wave.duration = duration
	wave.total_zombies = total
	wave.spawn_interval = interval
	wave.max_alive = max_alive
	return wave


func _schedule(countdown: float = 1.0) -> WaveSchedule:
	var wave_set := WaveSetConfig.new()
	wave_set.waves = [_wave(10.0, 3, 2.0, 2), _wave(10.0, 5, 1.0, 10), _wave(5.0, 1, 1.0, 1)]
	wave_set.break_duration = 4.0
	wave_set.initial_countdown = countdown
	var schedule := WaveSchedule.new(wave_set)
	schedule.start()
	return schedule


func test_project_config_has_exactly_three_waves() -> void:
	# RF-70, CA-09: the real resource.
	var wave_set := load("res://config/waves/wave_set.tres") as WaveSetConfig
	assert_eq(wave_set.waves.size(), 3)
	assert_eq(wave_set.waves[2].total_zombies, 30)
	assert_gt(wave_set.waves[2].speed_multiplier, wave_set.waves[0].speed_multiplier, "RF-73: harder")


func test_countdown_then_wave_spawns_first_zombie_at_once() -> void:
	var schedule := _schedule()
	assert_eq(schedule.phase, WaveSchedule.Phase.COUNTDOWN)
	assert_eq(schedule.tick(0.5, 0), 0, "nothing during the countdown")
	schedule.tick(0.6, 0)
	assert_eq(schedule.phase, WaveSchedule.Phase.WAVE)
	assert_eq(schedule.tick(0.01, 0), 1, "first zombie right away")
	assert_eq(schedule.tick(1.0, 1), 0, "waits the spawn interval")
	assert_eq(schedule.tick(1.0, 1), 1)
	assert_eq(schedule.pending(), 1)


func test_max_alive_and_total_are_respected() -> void:
	var schedule := _schedule(0.0)
	assert_eq(schedule.tick(0.01, 0), 1)
	assert_eq(schedule.tick(2.0, 2), 0, "RF-71: max alive reached")
	assert_eq(schedule.tick(0.01, 1), 1)
	assert_eq(schedule.tick(2.0, 0), 1)
	assert_eq(schedule.tick(2.0, 0), 0, "total reached")
	assert_eq(schedule.pending(), 0)


func test_wave_ends_by_time_then_break_then_next_wave() -> void:
	var schedule := _schedule(0.0)
	watch_signals(schedule)
	schedule.tick(10.1, 0)
	assert_eq(schedule.phase, WaveSchedule.Phase.BREAK, "RF-72: ends when time runs out")
	assert_eq(schedule.wave_index, 1)
	assert_eq(schedule.tick(1.0, 0), 0, "no spawns during the break")
	schedule.tick(3.1, 0)
	assert_eq(schedule.phase, WaveSchedule.Phase.WAVE)
	assert_eq(schedule.spawned_in_wave, 0, "counter resets per wave")


func test_finishes_after_the_last_wave() -> void:
	var schedule := _schedule(0.0)
	schedule.tick(10.1, 0)
	schedule.tick(4.1, 0)
	schedule.tick(10.1, 0)
	schedule.tick(4.1, 0)
	assert_true(schedule.is_last_wave())
	schedule.tick(5.1, 0)
	assert_eq(schedule.phase, WaveSchedule.Phase.FINISHED)
	assert_eq(schedule.tick(1.0, 0), 0)
