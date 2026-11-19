class_name AmmoPickup
extends Area3D
## Shotgun shells collected on contact (spec 001 RF-56, RF-57, RF-59). Shells that do not
## fit in the reserve stay in the box, so standing on it after firing picks up the rest.
## Zombie drops expire after `lifetime`; map crates (lifetime 0) also glow and pulse so
## they can be found while exploring.

signal collected(pickup: AmmoPickup)

## Shells inside the box.
@export var amount: int = 4
## Seconds before it disappears; 0 keeps it until collected.
@export var lifetime: float = 0.0
@export var pickup_sound: AudioStream

var _glow_config: AmmoSpawnConfig = null
var _is_collected := false
## "Reserve full" is reported once per contact, not every frame.
var _full_reported := false


## Optional setup before adding to the tree.
func configure(shells: int, seconds_alive: float, glow_config: AmmoSpawnConfig = null) -> void:
	amount = shells
	lifetime = seconds_alive
	_glow_config = glow_config


func _ready() -> void:
	if lifetime > 0.0:
		# process_always = false: the countdown stops while the game is paused.
		get_tree().create_timer(lifetime, false).timeout.connect(_expire)
	if _glow_config != null:
		_add_glow(_glow_config)


func _physics_process(_delta: float) -> void:
	if _is_collected:
		return
	for body in get_overlapping_bodies():
		if body is PlayerController:
			_try_collect(body as PlayerController)
			return
	_full_reported = false


func _try_collect(player: PlayerController) -> void:
	var weapons := player.get_node_or_null("WeaponManager") as WeaponManager
	if weapons == null or amount <= 0:
		return
	var added := weapons.add_ammo(amount)
	if added <= 0:
		if not _full_reported:
			_full_reported = true
			EventBus.ammo_reserve_full.emit()
		return
	amount -= added
	EventBus.ammo_collected.emit(added)
	Sfx.play_at(self, pickup_sound, global_position)
	if amount <= 0:
		_is_collected = true
		collected.emit(self)
		queue_free()


func _expire() -> void:
	if not _is_collected:
		queue_free()


## Pulsing colored light plus emissive material on the box (RF-59).
func _add_glow(glow: AmmoSpawnConfig) -> void:
	var light := OmniLight3D.new()
	light.light_color = glow.light_color
	light.omni_range = glow.light_range
	light.light_energy = glow.light_energy
	light.shadow_enabled = false
	light.position = Vector3.UP * 0.6
	add_child(light)
	var materials: Array[StandardMaterial3D] = []
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.get_surface_override_material_count():
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as StandardMaterial3D
			material.emission_enabled = true
			material.emission = glow.light_color
			material.emission_energy_multiplier = 0.4
			mesh.set_surface_override_material(surface, material)
			materials.append(material)
	var half := maxf(glow.pulse_period, 0.1) * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(light, "light_energy", glow.light_energy * 0.25, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_method(_set_emission.bind(materials), 1.2, 0.2, half)
	tween.tween_property(light, "light_energy", glow.light_energy, half) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_method(_set_emission.bind(materials), 0.2, 1.2, half)


func _set_emission(energy: float, materials: Array[StandardMaterial3D]) -> void:
	for material in materials:
		material.emission_energy_multiplier = energy
