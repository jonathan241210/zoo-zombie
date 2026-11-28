class_name PlayerStatusHud
extends Control
## Player HUD block (spec 001 RF-100, RF-109): health, equipped weapon icon and ammo
## (`magazine / reserve`, or ∞ with the axe) with low/empty colors, coin balance,
## survival time and the food-carrying indicator.

@export var player: PlayerController
@export var shotgun: Shotgun
@export var score_manager: ScoreManager
@export var config: PlayerStatusHudConfig

@onready var _health_label: Label = %HealthLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _ammo_label: Label = %AmmoLabel
@onready var _weapon_icon: TextureRect = %WeaponIcon
@onready var _coins_label: Label = %CoinsLabel
@onready var _time_label: Label = %TimeLabel
@onready var _carry_label: Label = %CarryLabel

var _weapon: StringName = WeaponManager.SHOTGUN
var _shown_seconds := -1


func _ready() -> void:
	assert(config != null, "PlayerStatusHud needs a PlayerStatusHudConfig")
	player.health.health_changed.connect(_on_health_changed)
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.weapon_changed.connect(_on_weapon_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.player_carry_changed.connect(_on_carry_changed)
	_carry_label.text = tr("HUD_CARRYING_FOOD")
	_on_health_changed(player.health.current_health, player.health.max_health)
	_on_weapon_changed(_weapon)
	_on_score_changed(score_manager.coins)
	_on_carry_changed(false)


func _process(_delta: float) -> void:
	var seconds := floori(GameManager.survival_time)
	if seconds == _shown_seconds:
		return
	_shown_seconds = seconds
	_time_label.text = "%s  %d:%02d" % [tr("HUD_TIME"), seconds / 60, seconds % 60]


func get_ammo_color() -> Color:
	return _ammo_label.get_theme_color("font_color")


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "%s  %d / %d" % [tr("HUD_HEALTH"), roundi(current), roundi(maximum)]


func _on_ammo_changed(magazine: int, reserve: int) -> void:
	var color := config.ammo_color
	if _weapon == WeaponManager.AXE:
		_ammo_label.text = "%s  ∞" % tr("HUD_AMMO")
	else:
		_ammo_label.text = "%s  %d / %d" % [tr("HUD_AMMO"), magazine, reserve]
		if magazine <= 0:
			color = config.ammo_empty_color
		elif reserve <= config.low_reserve_threshold:
			color = config.ammo_warning_color
	_ammo_label.add_theme_color_override("font_color", color)


func _on_weapon_changed(weapon_id: StringName) -> void:
	_weapon = weapon_id
	_weapon_icon.texture = config.axe_icon if weapon_id == WeaponManager.AXE else config.shotgun_icon
	_on_ammo_changed(shotgun.ammo.magazine, shotgun.ammo.reserve)


func _on_score_changed(coins: int) -> void:
	_coins_label.text = "%s  %d" % [tr("HUD_COINS"), coins]


func _on_carry_changed(is_carrying: bool) -> void:
	_carry_label.visible = is_carrying
