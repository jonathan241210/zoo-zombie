class_name EnclosureRegistry
extends Node
## Owns every Enclosure in the match (animal homes + refuges) and which animal lives in
## each one. Other systems ask the registry instead of searching the scene tree.

@export var config: EnclosureConfig

var _enclosures: Dictionary = {}  # map name -> Enclosure


## Creates enclosures for the given home names plus the configured refuges.
func setup(level: ZooLevel, home_names: PackedStringArray) -> void:
	var names := home_names.duplicate()
	for refuge in config.refuge_enclosures:
		if not names.has(refuge):
			names.append(refuge)
	for map_name in names:
		var map_node := level.find_map_node(map_name)
		if map_node == null:
			push_error("EnclosureRegistry: map node '%s' not found" % map_name)
			continue
		var enclosure := Enclosure.new()
		level.add_child(enclosure)
		enclosure.setup(map_node, level.get_feeder_anchor(map_name))
		_enclosures[map_name] = enclosure


func get_enclosure(map_name: String) -> Enclosure:
	return _enclosures.get(map_name) as Enclosure


func get_all() -> Array[Enclosure]:
	var result: Array[Enclosure] = []
	for enclosure: Enclosure in _enclosures.values():
		result.append(enclosure)
	return result


## Moves an animal into an enclosure (initial placement now; recapture in phase 7).
func assign(animal: Animal, enclosure: Enclosure) -> void:
	if animal.enclosure != null and animal.enclosure.occupant == animal:
		animal.enclosure.occupant = null
	enclosure.occupant = animal
	animal.enter_enclosure(enclosure)
