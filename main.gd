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
	repopulate_levels()
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
	
	var level_sequence = [
		"welcome",
		"basics",
		"blob-create",
		"blob-remove",
		"index-add",
		"index-remove",
		"index-update",
		"tree-create",
		"tree-read",
		"tree-nested",
		"commit-create",
		"commit-parents",
		"commit-rhombus",
		"ref-create",
		"ref-move",
		"ref-remove",
		"symref-create",
		"symref-no-deref",
	]
	
	for level in level_sequence:
		if not levels.has(level):
			push_error("Level '%s' is specified in the sequence, but could not be found" % level)
		levels.erase(level)
	
	level_sequence += levels
	
	return level_sequence

func load_level(id):
	$NextLevelButton.hide()
	$LevelCongrats.hide()
	$LevelDescription.show()
	current_level = id
	
	var levels = list_levels()
	
	var level = levels[id]
	var level_prefix = "res://levels/"
	
	var goal_repository_path = "/tmp/goal/"
	var active_repository_path = "/tmp/active/"
	var goal_script = level_prefix+level+"/goal"
	var active_script = level_prefix+level+"/start"
	
	var description_file = level_prefix+level+"/description"
	var description = game.read_file(description_file, "no description")
	$LevelDescription.bbcode_text = description
	
	var congrats_file = level_prefix+level+"/congrats"
	var congrats = game.read_file(congrats_file, "Good job, you solved the level!\n\nFeel free to try a few more things or click 'Next Level'.")
	$LevelCongrats.bbcode_text = congrats
	
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
		
	var goal_script_content = game.read_file(goal_script, "")
	var active_script_content = game.read_file(active_script, "")
	construct_repo(active_script_content +"\n"+ goal_script_content, goal_repository_path)
	construct_repo(active_script_content, active_repository_path)
	
	goal_repository.path = goal_repository_path
	active_repository.path = active_repository_path
	
	var win_script = level_prefix+level+"/win"
	var win_script_target = game.tmp_prefix+"/win"
	var win_script_content = game.read_file(win_script, "exit 1\n")
	game.write_file(win_script_target, win_script_content)
	
	terminal.clear()

func reload_level():
	load_level(current_level)

func load_next_level():
	current_level = (current_level + 1) % list_levels().size()
	load_level(current_level)
	
func construct_repo(script_content, path):
	# Becase in an exported game, all assets are in a .pck file, we need to put
	# the script somewhere in the filesystem.
	
	var script_path_outside = game.tmp_prefix+"/git-hydra-script"
	var script_path = "/tmp/git-hydra-script"
	game.write_file(script_path_outside, script_content)
	
	game.global_shell.run("mkdir " + path)
	game.global_shell.cd(path)
	game.global_shell.run("git init")
	game.global_shell.run("git symbolic-ref HEAD refs/heads/main")
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
	var content = game.read_file(fixme_path+filename, "[ERROR_FAKE_EDITOR]")
	if content == "[ERROR_FAKE_EDITOR]":
		push_error("file specified by fake-editor could not be read.")
		get_tree().quit()
	$TextEditor.text = content
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
	$LevelDescription.hide()
	$LevelCongrats.show()


func repopulate_levels():
	var options = $LevelSelect.get_popup()
	options.clear()
	for level in list_levels():
		options.add_item(level)
