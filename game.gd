extends Node

var tmp_prefix = _tmp_prefix()
var global_shell
var fake_editor

var _file = "user://savegame.json"
var state = {}

func _ready():
	global_shell = Shell.new()
	fake_editor = copy_file_to_game_env("fake-editor")
	copy_file_to_game_env("fake-editor-noblock")
	load_state()
	
func _initial_state():
	return {"history": []}
	
func save_state() -> bool:
	var savegame = File.new()
	
	savegame.open(_file, File.WRITE)
	savegame.store_line(to_json(state))
	savegame.close()
	return true
	
func load_state() -> bool:
	var savegame = File.new()
	if not savegame.file_exists(_file):
		save_state()
	
	savegame.open(_file, File.READ)
	
	state = _initial_state()
	var new_state = parse_json(savegame.get_line())
	for key in new_state:
		state[key] = new_state[key]
	savegame.close()
	return true
	
func copy_file_to_game_env(filename):
	# Copy fake-editor to tmp directory (because the original might be in a .pck file).
	var file_outside = tmp_prefix + filename
	var file_inside = "/tmp/"+filename
	var content = helpers.read_file("res://scripts/"+filename)
	helpers.write_file(file_outside, content)
	global_shell.run("chmod u+x " + file_inside)
	return file_inside

func _tmp_prefix():
	var os = OS.get_name()
	if os == "X11":
		return "/tmp/"
	elif os == "Windows":
		# For some reason, this command outputs a space in the end? We remove it.
		# Also, Godot's default is to use forward slashes for everything.
		return helpers.exec("echo", ["%TEMP%"]).replacen("\\", "/").replace(" \n", "/")
	else:
		helpers.crash("Unsupported OS: %s" % os)
