extends Control

var dragged = null

var chapter = "bottom-up"
var current_level = 0

onready var terminal = $Columns/RightSide/Terminal
onready var input = terminal.input
onready var output = terminal.output
onready var goal_repository = $Columns/Repositories/GoalRepository
onready var active_repository = $Columns/Repositories/ActiveRepository
onready var level_select = $Columns/RightSide/TopStuff/Menu/LevelSelect
onready var chapter_select = $Columns/RightSide/TopStuff/Menu/ChapterSelect
onready var next_level_button = $Columns/RightSide/TopStuff/Menu/NextLevelButton
onready var level_name = $Columns/RightSide/TopStuff/LevelPanel/LevelName
onready var level_description = $Columns/RightSide/TopStuff/LevelPanel/Text/LevelDescription
onready var level_congrats = $Columns/RightSide/TopStuff/LevelPanel/Text/LevelCongrats

func _ready():
	# Initialize level select.
	level_select.connect("item_selected", self, "load_level")
	repopulate_levels()
	level_select.select(0)
	
	# Initialize chapter select.
	chapter_select.connect("item_selected", self, "load_chapter")
	repopulate_chapters()
	chapter_select.select(0)
	
	# Load first level.
	load_level(0)
	input.grab_focus()
	
func list_chapters():
	var chapters = []
	var dir = Directory.new()
	dir.open("res://levels/")
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			chapters.append(file)

	dir.list_dir_end()
	chapters.sort()
	return chapters
	
func list_levels():
	var levels = []
	var dir = Directory.new()
	dir.open("res://levels/%s" % chapter)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file != "sequence":
			levels.append(file)

	dir.list_dir_end()
	levels.sort()
	
	var final_level_sequence = []
	
	var level_sequence = Array(helpers.read_file("res://levels/%s/sequence" % chapter, "").split("\n"))
	
	for level in level_sequence:
		if level == "":
			continue
		if not levels.has(level):
			helpers.crash("Level '%s' is specified in the sequence, but could not be found" % level)
		levels.erase(level)
		final_level_sequence.push_back(level)
	
	final_level_sequence += levels
	
	return final_level_sequence

func load_chapter(id):
	var chapters = list_chapters()
	chapter = chapters[id]
	load_level(0)

func load_level(id):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	
	next_level_button.hide()
	level_congrats.hide()
	level_description.show()
	current_level = id
	
	var levels = list_levels()
	
	var level = levels[id]
	var level_prefix = "res://levels/%s/" % chapter
	
	var goal_repository_path = game.tmp_prefix_inside+"/repos/goal/"
	var active_repository_path = game.tmp_prefix_inside+"/repos/active/"
	var goal_script = level_prefix+level+"/goal"
	var active_script = level_prefix+level+"/start"
	
	var description_file = level_prefix+level+"/description"
	var description = helpers.read_file(description_file, "(no description)")
	
	# Surround all lines indented with four spaces with [code] tags.
	var monospace_regex = RegEx.new()
	monospace_regex.compile("\n    (.*)\n")
	description = monospace_regex.sub(description, "\n      [code]$1[/code]\n", true)
	level_description.bbcode_text = description
	
	var congrats_file = level_prefix+level+"/congrats"
	var congrats = helpers.read_file(congrats_file, "Good job, you solved the level!\n\nFeel free to try a few more things or click 'Next Level'.")
	level_congrats.bbcode_text = congrats
	
	level_name.text = level
	
	# We're actually destroying stuff here.
	# Make sure that active_repository is in a temporary directory.
	_careful_delete(active_repository_path)
	_careful_delete(goal_repository_path)
		
	var goal_script_content = helpers.read_file(goal_script, "")
	var active_script_content = helpers.read_file(active_script, "")
	construct_repo(active_script_content +"\n"+ goal_script_content, goal_repository_path)
	construct_repo(active_script_content, active_repository_path)
	
	goal_repository.path = goal_repository_path
	active_repository.path = active_repository_path
	
	var win_script = level_prefix+level+"/win"
	var win_script_target = game.tmp_prefix_outside+"/win"
	var win_script_content = helpers.read_file(win_script, "exit 1\n")
	helpers.write_file(win_script_target, win_script_content)
	
	terminal.clear()
	
	# Unmute the audio after a while, so that player can hear pop sounds for
	# nodes they create.
	var t = Timer.new()
	t.wait_time = 3
	add_child(t)
	t.start()
	yield(t, "timeout")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	# FIXME: Need to clean these up when switching levels somehow.
	
func _careful_delete(path_inside):
	var expected_prefix
	
	var os = OS.get_name()
	
	if os == "X11":
		expected_prefix = "/home/%s/.local/share/git-hydra/tmp/" % OS.get_environment("USER")
	elif os == "Windows":
		helpers.crash("Need to figure out delete_prefix on Windows")
	else:
		helpers.crash("Unsupported OS: %s" % os)
	
	if path_inside.substr(0,expected_prefix.length()) != expected_prefix:
		helpers.crash("Refusing to delete directory %s that does not start with %s" % [path_inside, expected_prefix])
	else:
		game.global_shell.run("rm -rf '%s'" % path_inside)

func reload_level():
	load_level(current_level)

func load_next_level():
	current_level = (current_level + 1) % list_levels().size()
	load_level(current_level)
	
func construct_repo(script_content, path):
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
	
func show_win_status():
	next_level_button.show()
	level_description.hide()
	level_congrats.show()

func repopulate_levels():
	level_select.clear()
	for level in list_levels():
		level_select.add_item(level)

func repopulate_chapters():
	chapter_select.clear()
	for chapter in list_chapters():
		chapter_select.add_item(chapter)
