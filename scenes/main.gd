extends Control

var dragged = null

var current_chapter
var current_level

onready var terminal = $Rows/Controls/Terminal
onready var input = terminal.input
onready var output = terminal.output
onready var repositories_node = $Rows/Columns/Repositories
var repositories = {}
onready var level_select = $Rows/Columns/RightSide/LevelInfo/Menu/LevelSelect
onready var chapter_select = $Rows/Columns/RightSide/LevelInfo/Menu/ChapterSelect
onready var next_level_button = $Rows/Columns/RightSide/LevelInfo/Menu/NextLevelButton
onready var level_name = $Rows/Columns/RightSide/LevelInfo/LevelPanel/LevelName
onready var level_description = $Rows/Columns/RightSide/LevelInfo/LevelPanel/Text/LevelDescription
onready var level_congrats = $Rows/Columns/RightSide/LevelInfo/LevelPanel/Text/LevelCongrats
onready var cards = $Rows/Controls/Cards
onready var file_browser = $Rows/Columns/RightSide/FileBrowser
onready var index = $Rows/Columns/RightSide/Index

func _ready():
	var args = helpers.parse_args()
	
	if args.has("sandbox"):
		var err = get_tree().change_scene("res://scenes/sandbox.tscn")
		if err != OK:
			helpers.crash("Could not change to sandbox scene")
		return
		
	current_chapter = 0
	current_level = 0
	
	# Initialize level select.
	level_select.connect("item_selected", self, "load_level")
	repopulate_levels()
	level_select.select(current_level)
	
	# Initialize chapter select.
	chapter_select.connect("item_selected", self, "load_chapter")
	repopulate_chapters()
	chapter_select.select(current_chapter)
	
	# Load first chapter.
	load_chapter(current_chapter)
	input.grab_focus()

func load_chapter(id):
	current_chapter = id
	repopulate_levels()
	load_level(0)

func load_level(level_id):
	next_level_button.hide()
	level_congrats.hide()
	level_description.show()
	current_level = level_id
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	
	levels.chapters[current_chapter].levels[current_level].construct()

	var level = levels.chapters[current_chapter].levels[current_level]
	level_description.bbcode_text = level.description
	level_congrats.bbcode_text = level.congrats
	level_name.text = level.title
	cards.draw(levels.chapters[current_chapter].levels[current_level].cards)
	
	for r in repositories_node.get_children():
		r.queue_free()
	repositories = {}
	
	var repo_names = level.repos.keys()
	repo_names.invert()
	
	for r in repo_names:
		var repo = level.repos[r]
		var new_repo = preload("res://scenes/repository.tscn").instance()
		new_repo.path = repo.path
		new_repo.label = repo.slug
		new_repo.size_flags_horizontal = SIZE_EXPAND_FILL
		new_repo.size_flags_vertical = SIZE_EXPAND_FILL
		if new_repo.label == "yours":
			file_browser.shell = new_repo.shell
			file_browser.update()
			index.repository = new_repo
			index.update()
		repositories_node.add_child(new_repo)		
		repositories[r] = new_repo
	
	terminal.repository = repositories[repo_names[repo_names.size()-1]]
	terminal.clear()
	terminal.find_node("TextEditor").close()
	
	# Unmute the audio after a while, so that player can hear pop sounds for
	# nodes they create.
	var t = Timer.new()
	t.wait_time = 1
	add_child(t)
	t.start()
	yield(t, "timeout")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	# FIXME: Need to clean these up when switching levels somehow.
	
	chapter_select.select(current_chapter)
	level_select.select(current_level)

func reload_level():
	levels.reload()
	load_level(current_level)

func load_next_level():
	current_level = (current_level + 1) % levels.chapters[current_chapter].levels.size()
	load_level(current_level)
	
func show_win_status():
	if not level_congrats.visible:
		next_level_button.show()
		level_description.hide()
		level_congrats.show()
		$SuccessSound.play()

func repopulate_levels():
	levels.reload()
	level_select.clear()
	for level in levels.chapters[current_chapter].levels:
		level_select.add_item(level.title)
	level_select.select(current_level)

func repopulate_chapters():
	levels.reload()
	chapter_select.clear()
	for c in levels.chapters:
		chapter_select.add_item(c.slug)
	chapter_select.select(current_chapter)

func update_repos():
	for r in repositories:
		var repo = repositories[r]
		repo.update_everything()
	file_browser.update()
	index.update()
	
	if levels.chapters[current_chapter].levels[current_level].check_win():
		show_win_status()

func toggle_cards():
	cards.visible = not cards.visible
