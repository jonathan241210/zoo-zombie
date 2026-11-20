class_name WaveHud
extends Label
## Top-centre wave line (spec 001 RF-100, RF-10A, CA-09): current wave out of the total,
## time left in the current phase and the zombie counter (alive · still to appear).

@export var waves: WaveManager

var _alive := 0
var _pending := 0
var _refresh := 0.0


func _ready() -> void:
	assert(waves != null)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.zombie_count_changed.connect(func(alive: int, pending: int) -> void:
		_alive = alive
		_pending = pending)
	_update_text()


func _process(delta: float) -> void:
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.2
		_update_text()


func _update_text() -> void:
	var schedule := waves.schedule
	if schedule == null or not waves.enabled:
		text = ""
		return
	var number := schedule.wave_index + 1
	var total := schedule.wave_count()
	var clock := _clock(waves.time_left())
	match schedule.phase:
		WaveSchedule.Phase.COUNTDOWN:
			text = tr("HUD_WAVE_COUNTDOWN").format({"wave": number, "time": clock})
		WaveSchedule.Phase.WAVE:
			text = tr("HUD_WAVE_ACTIVE").format({"wave": number, "total": total, "time": clock,
				"alive": _alive, "pending": _pending})
		WaveSchedule.Phase.BREAK:
			text = tr("HUD_WAVE_BREAK").format({"wave": number, "time": clock, "alive": _alive})
		WaveSchedule.Phase.FINISHED:
			text = tr("HUD_WAVE_DONE").format({"total": total})


static func _clock(seconds: float) -> String:
	var whole := ceili(seconds)
	return "%d:%02d" % [floori(whole / 60.0), whole % 60]
