class_name AnimalHealthHud
extends Control
## Shows one compact health row per living animal near the player.

@export var player: PlayerController
@export var config: AnimalHealthHudConfig

@onready var _rows: VBoxContainer = %Rows

var _indicators: Dictionary = {}  # Animal -> AnimalHealthIndicator
var _refresh_elapsed := 0.0


func _ready() -> void:
	assert(player != null and config != null)
	EventBus.animal_registered.connect(_register_animal)


func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed < 1.0 / maxf(config.update_frequency, 1.0):
		return
	_refresh_elapsed = 0.0
	for animal: Animal in _indicators.keys():
		var indicator: AnimalHealthIndicator = _indicators[animal]
		if not is_instance_valid(animal):
			indicator.queue_free()
			_indicators.erase(animal)
			continue
		var in_range := animal.global_position.distance_to(player.global_position) <= config.visible_distance
		var should_show := in_range and not animal.health.is_dead
		indicator.visible = should_show


func _register_animal(node: Node3D) -> void:
	if not (node is Animal):
		return
	var animal := node as Animal
	if _indicators.has(animal):
		return
	var indicator := AnimalHealthIndicator.new()
	indicator.configure(animal, config)
	indicator.visible = false
	_rows.add_child(indicator)
	_indicators[animal] = indicator
