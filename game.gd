extends Node

var _file = "user://savegame.json"
var state = {}

func _ready():
	load_state()
	
func _initial_state():
	return {}
	
func save_state() -> bool:
	var savegame = File.new()
	
	savegame.open(_file, File.WRITE)
	savegame.store_line(to_json(state))
	savegame.close()
	return true
	
func load_state() -> bool:
	var savegame = File.new()
	if not savegame.file_exists(_file):
		return false
	
	savegame.open(_file, File.READ)
	
	state = _initial_state()
	var new_state = parse_json(savegame.get_line())
	for key in new_state:
		state[key] = new_state[key]
	savegame.close()
	return true
