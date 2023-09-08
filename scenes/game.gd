extends Node

var tmp_prefix = get_tmp_prefix()
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

var mutex

func get_tmp_prefix():
	if OS.get_name() == "Web":
		return "/tmp/"
	else:
		return OS.get_user_data_dir() + "/tmp/"

func _ready():
	mutex = Mutex.new()
	load_state()
	
	if OS.has_feature("standalone"):
		get_tree().set_auto_accept_quit(false)
	else:
		game.toggle_music()
	
	if OS.get_name() == "Windows":
		start_remote_shell()
	global_shell = await new_shell()

	if false:
		if (await global_shell.run("command -v git &>/dev/null && echo yes || echo no")) == "no\n":
			game.skipped_title = true
			get_tree().change_scene_to_file("res://scenes/no_git.tscn")
		else:
			await create_file_in_game_env(".gitconfig", helpers.read_file("res://scripts/gitconfig"))
			
			await copy_script_to_game_env("fake-editor")
			await copy_script_to_game_env("hint")

func start_remote_shell():
	var user_dir = ProjectSettings.globalize_path("user://")
	var script_content = helpers.read_file("res://scripts/net-test")
	var target_filename = user_dir + "net-test"
	var target_file = FileAccess.open(target_filename,FileAccess.WRITE)
	#target_file.open(target_filename, File.WRITE)
	target_file.store_string(script_content)
	target_file.close()
	helpers.exec_async(_perl_executable(), [target_filename, _bash_executable()])

func _perl_executable():
	if OS.get_name() == "Windows":
		return "dependencies/windows/git/usr/bin/perl.exe"
	else:
		return "perl"

func _bash_executable():
	if OS.get_name() == "Windows":
		return "dependencies/windows/git/usr/bin/bash.exe"
	else:
		return "bash"

func shell_received(text):
	print(text)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		#get_tree().quit() # default behavio
		get_tree().change_scene_to_file("res://scenes/survey.tscn")
		

func copy_script_to_game_env(name):
	await create_file_in_game_env(name, helpers.read_file("res://scripts/%s" % name))
	await global_shell.run("chmod u+x '%s'" % (tmp_prefix + name))
	
func _initial_state():
	return {"history": [], "solved_levels": [], "received_hints": [], "cli_badge": [], "played_cards": []}
	
func save_state():
	var savegame = FileAccess.open(_file,FileAccess.WRITE)
	
	#savegame.open(_file, File.WRITE)
	savegame.store_line(JSON.new().stringify(state))
	savegame.close()
	
func load_state():
	var savegame = FileAccess.open(_file,FileAccess.READ)
	if not savegame:
		save_state()
	
	#savegame.open(_file, File.READ)
	
	state = _initial_state()
	var test_json_conv = JSON.new()
	test_json_conv.parse(savegame.get_line())
	var new_state = test_json_conv.get_data()
	for key in new_state:
		state[key] = new_state[key]
	savegame.close()
	
# filename is relative to the tmp directory!
func create_file_in_game_env(filename, content):
	print("CD-ing to tmp in create_file")
	await global_shell.cd(tmp_prefix)
	# Quoted HERE doc doesn't do any substitutions inside.
	await global_shell.run("cat > '%s' <<'HEREHEREHERE'\n%s\nHEREHEREHERE" % [filename, content])

func notify(text, target=null, hint_slug=null):
	if hint_slug:
		if not state.has("received_hints"):
			state["received_hints"] = []
		if hint_slug in state["received_hints"]:
			return
		
	var notification = preload("res://scenes/notification.tscn").instantiate()
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
	var music = game.find_child("Music")
	if music.volume_db > -20:
		music.volume_db -= 100
	else:
		music.volume_db += 100

func shell_test(command):
	mutex.lock()
	#print("go")
	#print(command)
	var before = Time.get_ticks_msec()
	
	while not $ShellServer._connected:
		$ShellServer._process(0.1)
	
	var response = $ShellServer.send(command)
	var after = Time.get_ticks_msec()
	#print("took " + str(after-before)+" ms")
	#print("stop")
	mutex.unlock()
	return response
	
func new_shell():
	if OS.get_name() == "Windows":
		return BetterShell.new()
	else:
		return await Shell.new()
