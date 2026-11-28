extends GutTest
## On-screen action messages in the real game scene (spec 001 RF-10B, CA-21).

const GAME := preload("res://scenes/main/game.tscn")

var game: Node3D
var player: PlayerController
var feed: ActionFeed
var _locale := ""


func before_each() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	game = GAME.instantiate()
	(game.get_node("WaveManager") as WaveManager).enabled = false
	add_child_autofree(game)
	# The start tutorial pauses the tree; dismiss it so the match runs.
	(game.get_node("HUD/TutorialPopup") as TutorialPopup)._continue_game()
	await wait_physics_frames(6)
	player = game.get_node("Player")
	player.input_enabled = false
	feed = game.get_node("HUD/ActionFeed")


func after_each() -> void:
	TranslationServer.set_locale(_locale)


func test_crate_pick_up_and_drop_messages() -> void:
	var carry: PlayerCarry = player.get_node("PlayerCarry")
	player.global_position = Vector3(10.0, 1.6, 9.0)
	await wait_physics_frames(3)
	carry.pick_up()
	assert_has(feed.visible_texts(), "Recogiste comida: llévala a un comedero")
	carry.drop()
	assert_has(feed.visible_texts(), "Soltaste la caja de comida")


func test_feeding_message_agrees_with_each_species() -> void:
	EventBus.animal_fed.emit(&"giraffe")
	EventBus.animal_fed.emit(&"elephant")
	assert_has(feed.visible_texts(), "Alimentaste a la jirafa")
	assert_has(feed.visible_texts(), "Alimentaste al elefante")


func test_ammo_pickup_message_shows_amount() -> void:
	var shotgun: Shotgun = player.get_node("Shotgun")
	shotgun.ammo.reserve = 0
	var pickup := (load("res://scenes/pickups/ammo_pickup.tscn") as PackedScene).instantiate() as AmmoPickup
	pickup.configure(4, 0.0)
	game.add_child(pickup)
	pickup.global_position = player.global_position
	await wait_physics_frames(4)
	assert_has(feed.visible_texts(), "+4 cartuchos")


func test_full_reserve_is_reported_once() -> void:
	EventBus.ammo_reserve_full.emit()
	EventBus.ammo_reserve_full.emit()
	var count := 0
	for text in feed.visible_texts():
		if text == "Munición llena":
			count += 1
	assert_eq(count, 1, "no repeats inside the cooldown")


func test_empty_magazine_hints_reload_key() -> void:
	var shotgun: Shotgun = player.get_node("Shotgun")
	player.input_enabled = true
	shotgun.ammo.magazine = 0
	shotgun.fire()
	assert_has(feed.visible_texts(), "Cargador vacío: recarga con R")


func test_weapon_switch_message() -> void:
	assert_false(feed.visible_texts().has("Escopeta equipada"), "not shown at the start")
	var weapons: WeaponManager = player.get_node("WeaponManager")
	player.input_enabled = true
	weapons.switch_to(WeaponManager.AXE)
	await wait_seconds(player.config.weapon_switch_time + 0.1)
	assert_has(feed.visible_texts(), "Hacha equipada")


func test_animal_weak_and_death_messages() -> void:
	EventBus.animal_weak_changed.emit(&"giraffe", true)
	EventBus.animal_died.emit(&"elephant", Vector3.ZERO)
	assert_has(feed.visible_texts(), "¡La jirafa está débil! Necesita comida")
	assert_has(feed.visible_texts(), "El elefante murió")


func test_stack_is_capped_and_messages_expire() -> void:
	for i in 6:
		EventBus.ammo_collected.emit(i + 1)
	assert_eq(feed.visible_texts().size(), feed.config.max_visible)
	await wait_seconds(feed.config.message_duration + 0.3)
	assert_eq(feed.visible_texts().size(), 0, "they disappear on their own")


func test_english_texts() -> void:
	TranslationServer.set_locale("en")
	EventBus.animal_fed.emit(&"elephant")
	assert_has(feed.visible_texts(), "You fed the elephant")


func test_phase_7_messages() -> void:
	EventBus.animal_escaped.emit(&"giraffe")
	EventBus.animal_state_changed.emit(&"elephant", Animal.State.FOLLOWING)
	EventBus.animal_recaptured.emit(&"giraffe", null)
	assert_has(feed.visible_texts(), "¡Cayó el recinto: la jirafa escapó!")
	assert_has(feed.visible_texts(), "El elefante te sigue: llévalo a un refugio libre")
	assert_has(feed.visible_texts(), "La jirafa está a salvo en un refugio")


func test_enclosure_attack_alert_uses_long_cooldown() -> void:
	var registry: EnclosureRegistry = game.get_node("EnclosureRegistry")
	var home := registry.get_enclosure("REC_HEX_CENTRAL")
	home.health.take_damage(1.0)
	home.health.take_damage(1.0)
	var count := 0
	for text in feed.visible_texts():
		if text == "¡Los zombis atacan el recinto de la jirafa!":
			count += 1
	assert_eq(count, 1)
