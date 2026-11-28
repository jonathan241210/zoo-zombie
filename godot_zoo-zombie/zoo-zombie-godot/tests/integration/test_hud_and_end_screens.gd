extends GutTest
## Phase 9 HUD in the real game scene (spec 001 RF-100, RF-101, RF-104 to RF-107,
## RF-109, CA-10, CA-25).

const GAME := preload("res://scenes/main/game.tscn")

var game: Node3D
var player: PlayerController
var _locale := ""


func before_each() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	game = GAME.instantiate()
	(game.get_node("WaveManager") as WaveManager).enabled = false
	add_child_autofree(game)
	await wait_physics_frames(2)
	# Dismiss the start tutorial so the match is PLAYING (victory/defeat need it).
	(game.get_node("HUD/TutorialPopup") as TutorialPopup)._continue_game()
	await wait_physics_frames(4)
	player = game.get_node("Player")
	player.input_enabled = false


func after_each() -> void:
	get_tree().paused = false
	TranslationServer.set_locale(_locale)


func _animal(id: StringName) -> Animal:
	for node in get_tree().get_nodes_in_group(&"animals"):
		if node is Animal and (node as Animal).config.animal_id == id:
			return node
	for node in game.find_children("*", "Animal", true, false):
		if (node as Animal).config.animal_id == id:
			return node
	return null


func _indicator_for(animal: Animal) -> AnimalHealthIndicator:
	var hud: AnimalHealthHud = game.get_node("HUD/AnimalHealthHud")
	return hud._indicators.get(animal)


func test_ammo_turns_red_when_magazine_is_empty_and_axe_shows_infinite() -> void:
	var hud: PlayerStatusHud = game.get_node("HUD/PlayerStatusHud")
	EventBus.ammo_changed.emit(0, 12)
	assert_eq(hud.get_ammo_color(), hud.config.ammo_empty_color)
	EventBus.ammo_changed.emit(3, hud.config.low_reserve_threshold)
	assert_eq(hud.get_ammo_color(), hud.config.ammo_warning_color)
	EventBus.weapon_changed.emit(WeaponManager.AXE)
	assert_string_contains((hud.get_node("%AmmoLabel") as Label).text, "∞")
	assert_eq((hud.get_node("%WeaponIcon") as TextureRect).texture, hud.config.axe_icon)


func test_carry_indicator_follows_signal() -> void:
	var label: Label = game.get_node("HUD/PlayerStatusHud").get_node("%CarryLabel")
	EventBus.player_carry_changed.emit(true)
	assert_true(label.visible)
	EventBus.player_carry_changed.emit(false)
	assert_false(label.visible)


func test_card_bars_update_independently() -> void:
	var giraffe := _animal(&"giraffe")
	assert_not_null(giraffe)
	var card := _indicator_for(giraffe)
	assert_not_null(card)
	card.refresh()
	assert_eq(card.get_integrity_ratio(), 1.0)
	assert_eq(card.get_health_ratio(), 1.0)
	giraffe.enclosure.health.take_damage(giraffe.enclosure.health.max_health * 0.5)
	assert_almost_eq(card.get_integrity_ratio(), 0.5, 0.01)
	assert_eq(card.get_health_ratio(), 1.0)
	giraffe.health.take_damage(giraffe.health.max_health * 0.25)
	assert_almost_eq(card.get_health_ratio(), 0.75, 0.01)
	assert_almost_eq(card.get_integrity_ratio(), 0.5, 0.01)
	assert_eq(card.get_status_text(), "En su recinto")


func test_escaped_animal_gets_marker_and_refuges_appear() -> void:
	var markers: ObjectiveMarkers = game.get_node("HUD/ObjectiveMarkers")
	assert_eq(markers.get_targets().size(), 0, "nothing to mark while animals are contained")
	var giraffe := _animal(&"giraffe")
	giraffe.enclosure.health.take_damage(giraffe.enclosure.health.max_health + 1.0)
	await wait_physics_frames(2)
	var keys := markers.get_targets().map(func(t: Dictionary) -> String: return t["label_key"])
	assert_has(keys, "ANIMAL_GIRAFFE")
	assert_has(keys, "HUD_REFUGE")


func test_victory_screen_shows_stats_and_pauses() -> void:
	EventBus.zombie_killed.emit(null)
	EventBus.animal_fed.emit(&"giraffe")
	GameManager.finish_victory()
	var screen: EndScreen = game.get_node("HUD/EndScreen")
	assert_true(screen.visible)
	assert_true(screen.won)
	assert_true(get_tree().paused)
	var text := (screen.get_node("%StatsLabel") as Label).text
	assert_string_contains(text, "Zombis eliminados: 1")
	assert_string_contains(text, "Comidas · Jirafa: 1")
	assert_string_contains(text, "Estado final · Elefante: En su recinto")
	assert_string_contains(text, "Tiempo de supervivencia")


func test_defeat_screen_after_both_animals_die() -> void:
	for id: StringName in [&"giraffe", &"elephant"]:
		var animal := _animal(id)
		animal.health.take_damage(animal.health.max_health + 1.0)
	await wait_physics_frames(2)
	var screen: EndScreen = game.get_node("HUD/EndScreen")
	assert_true(screen.visible)
	assert_false(screen.won)
	assert_eq((screen.get_node("%EndTitle") as Label).text, "Derrota")
	assert_string_contains((screen.get_node("%StatsLabel") as Label).text, "Estado final · Jirafa: Murió")
