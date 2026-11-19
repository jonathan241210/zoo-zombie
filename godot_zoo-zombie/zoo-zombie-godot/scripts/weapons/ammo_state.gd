class_name AmmoState
extends RefCounted
## Magazine and reserve state for the shotgun (spec 001 RF-51).

var magazine_size: int
var max_reserve: int
var magazine: int
var reserve: int


func _init(config: ShotgunConfig) -> void:
	magazine_size = maxi(config.magazine_size, 0)
	max_reserve = maxi(config.max_reserve, 0)
	magazine = magazine_size
	reserve = clampi(config.starting_reserve, 0, max_reserve)


func consume_shell() -> bool:
	if magazine <= 0:
		return false
	magazine -= 1
	return true


func reload() -> int:
	var loaded := mini(magazine_size - magazine, reserve)
	magazine += loaded
	reserve -= loaded
	return loaded


func add_reserve(amount: int) -> int:
	var added := mini(maxi(amount, 0), max_reserve - reserve)
	reserve += added
	return added
