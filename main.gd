extends Node2D

var dragged = null

var server
var client_connection

onready var input = $Terminal/Control/Input
onready var output = $Terminal/Control/Output
onready var goal_repository = $Repositories/GoalRepository
onready var active_repository = $Repositories/ActiveRepository

func _ready():
	# Initialize level select.
	var options = $LevelSelect.get_popup()
	for level in list_levels():
		options.add_item(level)
	options.connect("id_pressed", self, "load_level")
	
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
	var levels = list_levels()
	
	var level = levels[id]
	var level_prefix = "res://levels/"
	
	var goal_repository_path = "/tmp/goal/"
	var active_repository_path = "/tmp/active/"
	var goal_script = level_prefix+level+"/goal"
	var active_script = level_prefix+level+"/start"
	
	var description = game.read_file(level_prefix+level+"/description")
	$LevelDescription.bbcode_text = description
	
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
	
func construct_repo(script, path):
	# Becase in an exported game, all assets are in a .pck file, we need to put
	# the script somewhere in the filesystem.
	var content = game.read_file(script)
	var script_path_outside = game.tmp_prefix+"/git-hydra-script"
	var script_path = "/tmp/git-hydra-script"
	game.write_file(script_path_outside, content)
	
	game.global_shell.run("mkdir " + path)
	game.global_shell.cd(path)
	game.global_shell.run("git init")
	var o = game.global_shell.run("source "+script_path)
	
	if game.debug:
		print(o)
	
func _process(_delta):
	if server.is_connection_available():
		print("Client connected")
		client_connection = server.take_connection()
		read_commit_message()
	
func read_commit_message():
	$CommitMessage.show()
	input.editable = false
	var fixme_path = game.tmp_prefix+"/active"
	$CommitMessage.text = game.read_file(fixme_path+"/.git/COMMIT_EDITMSG")
	$CommitMessage.grab_focus()

func save_commit_message():
	var fixme_path = game.tmp_prefix+"/active"
	game.write_file(fixme_path+"/.git/COMMIT_EDITMSG", $CommitMessage.text)
	print("disconnect")
	client_connection.disconnect_from_host()
	input.editable = true
	$CommitMessage.text = ""
	$CommitMessage.hide()
	input.grab_focus()
