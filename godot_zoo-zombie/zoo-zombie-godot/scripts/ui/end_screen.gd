class_name EndScreen
extends Control
## Victory and defeat screens (spec 001 RF-105 to RF-107, CA-10): title, coin balance and
## match statistics, final state of each animal, survival time, and Restart / Quit.

const MAIN_MENU := "res://scenes/ui/menus/main_menu.tscn"

@export var player: PlayerController
## Pause the world while the screen is up. Tests that keep waiting after the match
## ends turn it off.
@export var pause_game := true

@onready var _title: Label = %EndTitle
@onready var _subtitle: Label = %EndSubtitle
@onready var _stats_label: Label = %StatsLabel
@onready var _restart_button: Button = %RestartButton
@onready var _quit_button: Button = %QuitButton

## animal_id -> {"name_key": String, "node": Animal}. Animals are freed after dying,
## so the name is kept here for the final summary.
var _animals: Dictionary = {}
var won := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_restart_button.text = tr("MENU_RESTART")
	_quit_button.text = tr("MENU_QUIT_TO_MENU")
	_restart_button.pressed.connect(GameManager.restart_match)
	_quit_button.pressed.connect(func() -> void: GameManager.return_to_menu(MAIN_MENU))
	EventBus.animal_registered.connect(_on_animal_registered)
	EventBus.game_won.connect(func(stats: Dictionary) -> void: show_results(stats, true))
	EventBus.game_lost.connect(func(stats: Dictionary) -> void: show_results(stats, false))


func show_results(stats: Dictionary, victory: bool) -> void:
	won = victory
	_title.text = tr("END_VICTORY_TITLE" if victory else "END_DEFEAT_TITLE")
	_subtitle.text = tr("END_VICTORY_SUBTITLE" if victory else "END_DEFEAT_SUBTITLE")
	_title.add_theme_color_override("font_color",
		Color(0.55, 0.95, 0.45) if victory else Color(0.95, 0.3, 0.25))
	_stats_label.text = build_stats_text(stats)
	# Hide the rest of the HUD (messages, markers, cards) so the summary reads cleanly.
	for sibling in get_parent().get_children():
		if sibling != self and sibling is CanvasItem:
			(sibling as CanvasItem).visible = false
	visible = true
	if pause_game:
		get_tree().paused = true
	if player != null:
		player.set_mouse_captured(false)
	_restart_button.grab_focus()


func build_stats_text(stats: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("%s: %d" % [tr("HUD_COINS"), int(stats.get("coins", 0))])
	lines.append("%s: %d" % [tr("END_ZOMBIES_KILLED"), int(stats.get("zombies_killed", 0))])
	var feedings: Dictionary = stats.get("feedings", {})
	var lost: Array = stats.get("animals_lost", [])
	for animal_id: StringName in _animals.keys():
		var name := tr(_animals[animal_id]["name_key"])
		lines.append("%s · %s: %d" % [tr("END_FEEDINGS"), name, int(feedings.get(animal_id, 0))])
	lines.append("%s: %d" % [tr("END_RECAPTURES"), int(stats.get("recaptures", 0))])
	lines.append("%s: %d" % [tr("END_ENCLOSURES_DESTROYED"), int(stats.get("enclosures_destroyed", 0))])
	lines.append("%s: %d" % [tr("END_PLAYER_DEATHS"), int(stats.get("player_deaths", 0))])
	for animal_id: StringName in _animals.keys():
		var entry: Dictionary = _animals[animal_id]
		var status := "ANIMAL_STATUS_DEAD"
		if not lost.has(animal_id) and is_instance_valid(entry["node"]):
			status = (entry["node"] as Animal).get_status_key()
		lines.append("%s · %s: %s" % [tr("END_FINAL_STATE"), tr(entry["name_key"]), tr(status)])
	var seconds := floori(float(stats.get("survival_time", 0.0)))
	lines.append("%s: %d:%02d" % [tr("END_SURVIVAL_TIME"), seconds / 60, seconds % 60])
	return "\n".join(lines)


func _on_animal_registered(node: Node3D) -> void:
	if node is Animal:
		var animal := node as Animal
		_animals[animal.config.animal_id] = {"name_key": animal.config.display_name_key, "node": animal}
