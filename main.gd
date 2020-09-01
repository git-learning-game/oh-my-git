extends Node2D

var dragged = null

var server
var client_connection

func _ready():
	# Initialize level select.
	var options = $LevelSelect.get_popup()
	for level in list_levels():
		options.add_item(level)
	options.connect("id_pressed", self, "load_level")
	
	# Initialize TCP server for fake editor.
	server = TCP_Server.new()
	server.listen(1234)
	
func list_levels():
	var levels = []
	var dir = Directory.new()
	dir.open("levels")
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			levels.append(file)

	dir.list_dir_end()
	return levels

func load_level(id):
	var levels = list_levels()
	
	var level = levels[id]
	var cwd = game.run("pwd")
	var tmp_prefix = "/tmp/"
	var level_prefix = cwd+"/levels/"
	
	var goal_repository_path = tmp_prefix+"goal/"
	var active_repository_path = tmp_prefix+"active/"
	var goal_script = level_prefix+level+"/goal"
	var active_script = level_prefix+level+"/start"
	
	OS.execute("rm", ["-r", active_repository_path], true)
	OS.execute("rm", ["-r", goal_repository_path], true)
	construct_repo(goal_script, goal_repository_path)
	construct_repo(active_script, active_repository_path)
	
	$GoalRepository.path = goal_repository_path
	$ActiveRepository.path = active_repository_path
	
func construct_repo(script, path):
	print(path)
	game.sh("mkdir "+path)
	game.sh("git init", path)
	var commands = game.read_file(script).split("\n")
	print(commands)
	for command in commands:
		print(command)
		game.sh(command, path)
	
func _process(delta):
	if server.is_connection_available():
		client_connection = server.take_connection()
		read_commit_message()
#	if true or get_global_mouse_position().x < get_viewport_rect().size.x*0.7:
#		if Input.is_action_just_pressed("click"):
#			var mindist = 9999999
#			for o in objects.values():
#				var d = o.position.distance_to(get_global_mouse_position())
#				if d < mindist:
#					mindist = d
#					dragged = o
#		if Input.is_action_just_released("click"):
#				dragged = null
#		if dragged:
#			dragged.position = get_global_mouse_position()

#func run(command):
#	var a = command.split(" ")
#	var cmd = a[0]
#	a.remove(0)
#	var output = []
#	OS.execute(cmd, a, true, output, true)
#	print(command)
#	print(output[0])
	
func read_commit_message():
	$CommitMessage.show()
	$Terminal/Input.editable = false
	$CommitMessage.text = game.read_file("/tmp/githydragit/.git/COMMIT_EDITMSG")

func save_commit_message():
	game.write_file("/tmp/githydragit/.git/COMMIT_EDITMSG", $CommitMessage.text)
	print("disconnect")
	client_connection.disconnect_from_host()
	$Terminal/Input.editable = true
	$CommitMessage.text = ""
	$CommitMessage.hide()
