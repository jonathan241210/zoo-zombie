class_name PlayerStatusHud
extends Control
## Player health and shotgun ammunition indicators (spec 001 RF-100, RF-109).

@export var player: PlayerController
@export var shotgun: Shotgun

@onready var _health_label: Label = %HealthLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _ammo_label: Label = %AmmoLabel


func _ready() -> void:
	player.health.health_changed.connect(_on_health_changed)
	EventBus.ammo_changed.connect(_on_ammo_changed)
	_on_health_changed(player.health.current_health, player.health.max_health)
	_on_ammo_changed(shotgun.ammo.magazine, shotgun.ammo.reserve)


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "%s  %d / %d" % [tr("HUD_HEALTH"), roundi(current), roundi(maximum)]


func _on_ammo_changed(magazine: int, reserve: int) -> void:
	_ammo_label.text = "%s  %d / %d" % [tr("HUD_AMMO"), magazine, reserve]
