extends Node
class_name Level

var slug
var description
var congrats
var start_commands
var goal_commands
var win_commands

# The path is an outer path.
func load(path):
	var parts = path.split("/")
	slug = parts[parts.size()-1]
	
	description = helpers.read_file(path+"/description", "(no description)")
	# Surround all lines indented with four spaces with [code] tags.
	var monospace_regex = RegEx.new()
	monospace_regex.compile("\n    (.*)\n")
	description = monospace_regex.sub(description, "\n      [code]$1[/code]\n", true)
	
	congrats = helpers.read_file(path+"/congrats", "Good job, you solved the level!\n\nFeel free to try a few more things or click 'Next Level'.")
	start_commands = helpers.read_file(path+"/start", "")
	goal_commands = helpers.read_file(path+"/goal", "")
	win_commands = helpers.read_file(path+"/win", "exit 1\n")

func construct():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	
	var goal_repository_path = game.tmp_prefix_inside+"/repos/goal/"
	var active_repository_path = game.tmp_prefix_inside+"/repos/active/"
	
	# We're actually destroying stuff here.
	# Make sure that active_repository is in a temporary directory.
	helpers.careful_delete(active_repository_path)
	helpers.careful_delete(goal_repository_path)
	
	_construct_repo(start_commands +"\n"+ goal_commands, goal_repository_path)
	_construct_repo(start_commands, active_repository_path)
	
	var win_script_target = game.tmp_prefix_outside+"/win"
	helpers.write_file(win_script_target, win_commands)
	
	# Unmute the audio after a while, so that player can hear pop sounds for
	# nodes they create.
	var t = Timer.new()
	t.wait_time = 3
	add_child(t)
	t.start()
	yield(t, "timeout")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	# FIXME: Need to clean these up when switching levels somehow.
	
func _construct_repo(script_content, path):
	# Becase in an exported game, all assets are in a .pck file, we need to put
	# the script somewhere in the filesystem.
	
	var script_path_outside = game.tmp_prefix_outside+"/git-hydra-script"
	var script_path_inside = game.tmp_prefix_inside+"/git-hydra-script"
	helpers.write_file(script_path_outside, script_content)
	
	game.global_shell.run("mkdir " + path)
	game.global_shell.cd(path)
	game.global_shell.run("git init")
	game.global_shell.run("git symbolic-ref HEAD refs/heads/main")
	# Read stdin from /dev/null so that interactive commands don't block.
	game.global_shell.run("bash "+script_path_inside+" </dev/null")
