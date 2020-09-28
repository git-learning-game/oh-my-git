extends Node

var tmp_prefix = _tmp_prefix()
var global_shell
var debug_file_io = false
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
	var content = game.read_file("res://scripts/"+filename, "")
	if content.empty():
		push_error(filename + " could not be read.")
	write_file(file_outside, content)
	global_shell.run("chmod u+x " + file_inside)
	return file_inside

func read_file(path, fallback_string):
	if debug_file_io:
		print("reading " + path)
	var file = File.new()
	var open_status = file.open(path, File.READ)
	if open_status == OK:
		var content = file.get_as_text()
		file.close()
		return content
	else:
		return fallback_string

func write_file(path, content):
	if debug_file_io:
		print("writing " + path)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()
	return true

func _tmp_prefix():
	var os = OS.get_name()
	if os == "X11":
		return "/tmp/"
	elif os == "Windows":
		# For some reason, this command outputs a space in the end? We remove it.
		# Also, Godot's default is to use forward slashes for everything.
		return exec("echo", ["%TEMP%"]).replacen("\\", "/").replace(" \n", "/")
	else:
		push_error("Unsupported OS")
		get_tree().quit()

# Run a simple command with arguments, blocking, using OS.execute.
func exec(command, args=[]):
	var debug = false
	
	if debug:
		print("exec: %s [%s]" % [command, PoolStringArray(args).join(", ")])
		
	var output = []
	var exit_code = OS.execute(command, args, true, output, true)
	output = output[0]
	
	if exit_code != 0:
		push_error("OS.execute failed: %s [%s] Output: %s" % [command, PoolStringArray(args).join(", "), output])
	
	if debug:
		print(output)

	return output
