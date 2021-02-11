extends Node

var tmp_prefix = OS.get_user_data_dir() + "/tmp/"
var global_shell
var fake_editor

var dragged_object
var energy = 2
var used_cards = false

var current_chapter = 0
var current_level = 0
var skipped_title = false

var _file = "user://savegame.json"
var state = {}

func _ready():
	if OS.has_feature("standalone"):
		get_tree().set_auto_accept_quit(false)
	
	global_shell = Shell.new()
	
	create_file_in_game_env(".gitconfig", helpers.read_file("res://scripts/gitconfig"))
	
	copy_script_to_game_env("fake-editor")
	copy_script_to_game_env("hint")
	
	load_state()
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		#get_tree().quit() # default behavio
		get_tree().change_scene("res://scenes/survey.tscn")
		

func copy_script_to_game_env(name):
	create_file_in_game_env(name, helpers.read_file("res://scripts/%s" % name))
	global_shell.run("chmod u+x '%s'" % (tmp_prefix + name))
	
func _initial_state():
	return {"history": [], "solved_levels": [], "received_hints": [], "cli_badge": []}
	
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
	
# filename is relative to the tmp directory!
func create_file_in_game_env(filename, content):
	global_shell.cd(tmp_prefix)
	# Quoted HERE doc doesn't do any substitutions inside.
	global_shell.run("cat > '%s' <<'HEREHEREHERE'\n%s\nHEREHEREHERE" % [filename, content])

func notify(text, target=null, hint_slug=null):
	if hint_slug:
		if not state.has("received_hints"):
			state["received_hints"] = []
		if hint_slug in state["received_hints"]:
			return
		
	var notification = preload("res://scenes/notification.tscn").instance()
	notification.text = text
	if not target:
		target = get_tree().root
	target.call_deferred("add_child", notification)
	
	if hint_slug:
		state["received_hints"].push_back(hint_slug)
		save_state()
		
func open_survey():
	OS.shell_open("https://docs.google.com/forms/d/e/1FAIpQLSehHVcYfELT59h6plcn2ilbuqBcmDX3TH0qzB4jCgFIFOy_qg/viewform")
	
func toggle_music():
	var music = game.find_node("Music")
	if music.volume_db > -20:
		music.volume_db -= 100
	else:
		music.volume_db += 100
