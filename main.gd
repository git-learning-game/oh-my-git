extends Node2D

var dragged = null

var server
var client_connection
var current_level = 0

onready var terminal = $Terminal
onready var input = terminal.input
onready var output = terminal.output
onready var goal_repository = $Repositories/GoalRepository
onready var active_repository = $Repositories/ActiveRepository

func _ready():
	# Initialize level select.
	var options = $LevelSelect.get_popup()
	for level in list_levels():
		options.add_item(level)
	options.connect("id_pressed", self, "load_level")
	$LevelSelect.theme = Theme.new()
	$LevelSelect.theme.default_font = load("res://fonts/default.tres")
	
	# Initialize TCP server for fake editor.
	server = TCP_Server.new()
	server.listen(1234)
	
	# Load first level.
	load_level(0)
	input.grab_focus()
	
func list_levels():
	var levels = []
	var dir = Directory.new()
	dir.open("res://levels")
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			levels.append(file)

	dir.list_dir_end()
	levels.sort()
	return levels

func load_level(id):
	$NextLevelButton.hide()
	current_level = id
	
	var levels = list_levels()
	
	var level = levels[id]
	var level_prefix = "res://levels/"
	
	var goal_repository_path = "/tmp/goal/"
	var active_repository_path = "/tmp/active/"
	var goal_script = level_prefix+level+"/goal"
	var active_script = level_prefix+level+"/start"
	
	var description = game.read_file(level_prefix+level+"/description")
	$LevelDescription.bbcode_text = description
	$LevelName.text = level
	
	# We're actually destroying stuff here.
	# Make sure that active_repository is in a temporary directory.
	var expected_prefix = "/tmp"
	if active_repository_path.substr(0,4) != expected_prefix:
		push_error("Refusing to delete a directory that does not start with %s" % expected_prefix)
		get_tree().quit()
	if goal_repository_path.substr(0,4) != expected_prefix:
		push_error("Refusing to delete a directory that does not start with %s" % expected_prefix)
		get_tree().quit()
	
	# Danger zone!
	game.global_shell.run("rm -rf '%s'" % active_repository_path)
	game.global_shell.run("rm -rf '%s'" % goal_repository_path)
	
	construct_repo(goal_script, goal_repository_path)
	construct_repo(active_script, active_repository_path)
	
	goal_repository.path = goal_repository_path
	active_repository.path = active_repository_path
	
	var win_script = level_prefix+level+"/win"
	var win_script_target = game.tmp_prefix+"/win"
	var dir = Directory.new()
	dir.copy(win_script, win_script_target)
	
	terminal.clear()

func reload_level():
	load_level(current_level)

func load_next_level():
	current_level = (current_level + 1) % list_levels().size()
	load_level(current_level)
	
func construct_repo(script, path):
	# Becase in an exported game, all assets are in a .pck file, we need to put
	# the script somewhere in the filesystem.
	var content = ""
	#if ResourceLoader.exists(script):
	content = game.read_file(script)
	var script_path_outside = game.tmp_prefix+"/git-hydra-script"
	var script_path = "/tmp/git-hydra-script"
	game.write_file(script_path_outside, content)
	
	game.global_shell.run("mkdir " + path)
	game.global_shell.cd(path)
	game.global_shell.run("git init")
	game.global_shell.run("sh "+script_path)
	
func _process(_delta):
	if server.is_connection_available():
		client_connection = server.take_connection()
		var length = client_connection.get_u8()
		var filename = client_connection.get_string(length)
		var regex = RegEx.new()
		regex.compile("(\\.git\\/.*)")
		filename = regex.search(filename).get_string()
		read_message(filename)
	
func read_message(filename):
	$TextEditor.show()
	input.editable = false
	var fixme_path = game.tmp_prefix+"/active/"
	$TextEditor.text = game.read_file(fixme_path+filename)
	$TextEditor.path = filename
	$TextEditor.grab_focus()

func save_message():
	var fixme_path = game.tmp_prefix+"/active/"
	game.write_file(fixme_path+$TextEditor.path, $TextEditor.text)
	client_connection.disconnect_from_host()
	input.editable = true
	$TextEditor.text = ""
	$TextEditor.hide()
	input.grab_focus()
	
func show_win_status():
	$NextLevelButton.show()
	$LevelDescription.text = "Yay, you solved the puzzle! Enjoy the view or continue to the next level!"
