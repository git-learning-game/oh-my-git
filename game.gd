extends Node

var tmp_prefix_outside = _tmp_prefix_outside()
var tmp_prefix_inside = _tmp_prefix_inside()
var global_shell
var fake_editor

var dragged_object

var _file = "user://savegame.json"
var state = {}

func _ready():
	var dir = Directory.new()
	if not dir.dir_exists(tmp_prefix_outside):
		var err = dir.make_dir(tmp_prefix_outside)
		if err != OK:
			helpers.crash("Could not create temporary directory %s." % tmp_prefix_outside)
	if not dir.dir_exists(tmp_prefix_outside+"/repos/"):
		var err = dir.make_dir(tmp_prefix_outside+"/repos/")
		if err != OK:
			helpers.crash("Could not create temporary directory %s." % (tmp_prefix_outside+"/repos/"))
	
	global_shell = Shell.new()
	fake_editor = copy_file_to_game_env("fake-editor")
	copy_file_to_game_env("fake-editor-noblock")
	load_state()
	
func _initial_state():
	return {"history": []}
	
func save_state():
	var savegame = File.new()
	
	savegame.open(_file, File.WRITE)
	savegame.store_line(to_json(state))
	savegame.close()
	
func load_state():
	var savegame = File.new()
	if not savegame.file_exists(_file):
		save_state()
	
	savegame.open(_file, File.READ)
	
	state = _initial_state()
	var new_state = parse_json(savegame.get_line())
	for key in new_state:
		state[key] = new_state[key]
	savegame.close()
	
func copy_file_to_game_env(filename):
	# Copy fake-editor to tmp directory (because the original might be in a .pck file).
	var file_outside = tmp_prefix_outside + filename
	var file_inside = tmp_prefix_inside + filename
	var content = helpers.read_file("res://scripts/"+filename)
	helpers.write_file(file_outside, content)
	global_shell.run("chmod u+x " + '"'+file_inside+'"')
	return file_inside

func _tmp_prefix_inside():
	var os = OS.get_name()
	var path
	if os == "X11" or os == "OSX":
		path = OS.get_user_data_dir()
	elif os == "Windows":
		helpers.crash("Need to figure out Windows tmp_prefix_inside...")
	else:
		helpers.crash("Unsupported OS: %s" % os)
	
	return path + "/tmp/"
	
func _tmp_prefix_outside():
	return "user://tmp/"
