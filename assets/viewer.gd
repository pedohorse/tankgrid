extends Node
class_name Viewer

var _is_initialized = false;

func initialize_viewer(map: String, battle_log: String):
	($root/Battler as Battler).initialize_battle(battle_log)
	($root/map as Map).initialize_map(map)
	_is_initialized = true
