extends Control

var dragged = null

var current_chapter
var current_level

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
	var args = helpers.parse_args()
	
	if args.has("sandbox"):
		var err = get_tree().change_scene("res://sandbox.tscn")
		if err != OK:
			helpers.crash("Could not change to sandbox scene")
		return
		
	current_chapter = 0
	current_level = 0
	
	# Initialize level select.
	level_select.connect("item_selected", self, "load_level")
	repopulate_levels()
	level_select.select(0)
	
	# Initialize chapter select.
	chapter_select.connect("item_selected", self, "load_chapter")
	repopulate_chapters()
	chapter_select.select(0)
	
	# Load first chapter.
	load_chapter(0)
	input.grab_focus()

func load_chapter(id):
	current_chapter = id
	load_level(0)

func load_level(level_id):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	
	next_level_button.hide()
	level_congrats.hide()
	level_description.show()
	current_level = level_id
	
	var goal_repository_path = game.tmp_prefix_inside+"/repos/goal/"
	var active_repository_path = game.tmp_prefix_inside+"/repos/active/"

	var level = levels.chapters[current_chapter].levels[current_level]
	level_description.bbcode_text = level.description
	level_congrats.bbcode_text = level.congrats
	level_name.text = level.slug
	
	# We're actually destroying stuff here.
	# Make sure that active_repository is in a temporary directory.
	helpers.careful_delete(active_repository_path)
	helpers.careful_delete(goal_repository_path)
		
	
	construct_repo(level.start_commands +"\n"+ level.goal_commands, goal_repository_path)
	construct_repo(level.start_commands, active_repository_path)
	
	goal_repository.path = goal_repository_path
	active_repository.path = active_repository_path
	
	var win_script_target = game.tmp_prefix_outside+"/win"
	helpers.write_file(win_script_target, level.win_commands)
	
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

func reload_level():
	load_level(current_level)

func load_next_level():
	current_level = (current_level + 1) % levels.chapters[current_chapter].size()
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
	levels.reload()
	level_select.clear()
	for level in levels.chapters[current_chapter].levels:
		level_select.add_item(level.slug)

func repopulate_chapters():
	levels.reload()
	chapter_select.clear()
	for c in levels.chapters:
		chapter_select.add_item(c.slug)
