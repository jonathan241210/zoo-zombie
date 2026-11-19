class_name Stamina
extends RefCounted
## Stamina of an escaped animal (spec 001 RF-41, RF-42). Running drains it; walking or
## resting restores it. At 0 the animal is tired until it recovers `recovery_ratio`.

signal tired_changed(is_tired: bool)

var max_value: float
var drain_per_second: float
var regen_per_second: float
var recovery_ratio: float
var value: float
var is_tired := false


func _init(maximum: float, drain: float, regen: float, recovery: float) -> void:
	max_value = maxf(maximum, 0.01)
	drain_per_second = drain
	regen_per_second = regen
	recovery_ratio = clampf(recovery, 0.0, 1.0)
	value = max_value


static func from_config(config: AnimalConfig) -> Stamina:
	return Stamina.new(config.max_stamina, config.stamina_drain_per_second,
		config.stamina_regen_per_second, config.tired_recovery_ratio)


## Advances the stamina; `running` drains it, anything else regenerates it.
func tick(delta: float, running: bool) -> void:
	if running and not is_tired:
		value = maxf(value - drain_per_second * delta, 0.0)
		if value <= 0.0:
			_set_tired(true)
	else:
		value = minf(value + regen_per_second * delta, max_value)
		if is_tired and value >= max_value * recovery_ratio:
			_set_tired(false)


func can_run() -> bool:
	return not is_tired


func ratio() -> float:
	return value / max_value


func _set_tired(tired: bool) -> void:
	if is_tired != tired:
		is_tired = tired
		tired_changed.emit(is_tired)
