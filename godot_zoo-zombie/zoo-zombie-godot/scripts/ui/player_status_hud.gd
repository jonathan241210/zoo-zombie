class_name PlayerStatusHud
extends Control
## Player health and ammunition indicators (spec 001 RF-100, RF-109). With the axe
## equipped the ammo reads as infinite.

@export var player: PlayerController
@export var shotgun: Shotgun
@export var score_manager: ScoreManager

@onready var _health_label: Label = %HealthLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _ammo_label: Label = %AmmoLabel
@onready var _coins_label: Label = %CoinsLabel

var _weapon: StringName = WeaponManager.SHOTGUN


func _ready() -> void:
	player.health.health_changed.connect(_on_health_changed)
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.weapon_changed.connect(_on_weapon_changed)
	EventBus.score_changed.connect(_on_score_changed)
	_on_health_changed(player.health.current_health, player.health.max_health)
	_on_ammo_changed(shotgun.ammo.magazine, shotgun.ammo.reserve)
	_on_score_changed(score_manager.coins)


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "%s  %d / %d" % [tr("HUD_HEALTH"), roundi(current), roundi(maximum)]


func _on_ammo_changed(magazine: int, reserve: int) -> void:
	if _weapon == WeaponManager.AXE:
		_ammo_label.text = "%s  ∞" % tr("HUD_AMMO")
	else:
		_ammo_label.text = "%s  %d / %d" % [tr("HUD_AMMO"), magazine, reserve]


func _on_weapon_changed(weapon_id: StringName) -> void:
	_weapon = weapon_id
	_on_ammo_changed(shotgun.ammo.magazine, shotgun.ammo.reserve)


func _on_score_changed(coins: int) -> void:
	_coins_label.text = "%s  %d" % [tr("HUD_COINS"), coins]
