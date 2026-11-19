class_name AnimalNeeds
extends RefCounted
## Animal satiety timer. When it is empty, health drains at the configured rate.

signal satiety_changed(ratio: float, seconds_remaining: float)
signal satiety_depleted

var config: AnimalConfig
var satiety_remaining: float = 0.0


func configure(animal_config: AnimalConfig) -> void:
	config = animal_config
	satiety_remaining = maxf(config.grace_period, 0.0)


func tick(delta: float) -> float:
	if satiety_remaining > 0.0:
		var remaining_before_tick := satiety_remaining
		satiety_remaining = maxf(satiety_remaining - delta, 0.0)
		satiety_changed.emit(satiety_ratio(), satiety_remaining)
		if is_zero_approx(satiety_remaining):
			satiety_depleted.emit()
			return maxf(delta - remaining_before_tick, 0.0) * config.starvation_damage_per_second
		return 0.0
	return config.starvation_damage_per_second * delta


func feed() -> void:
	satiety_remaining = maxf(config.grace_period, 0.0)
	satiety_changed.emit(satiety_ratio(), satiety_remaining)


func satiety_ratio() -> float:
	return satiety_remaining / config.grace_period if config.grace_period > 0.0 else 0.0
