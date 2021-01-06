extends Control

var dragged = null

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

var _hint_server
var _hint_client_connection

func _ready():
	_hint_server = TCP_Server.new()
	_hint_server.listen(1235)
	
	var args = helpers.parse_args()
	
	if args.has("sandbox"):
		var err = get_tree().change_scene("res://scenes/sandbox.tscn")
		if err != OK:
			helpers.crash("Could not change to sandbox scene")
		return
	
	# Initialize level select.
	level_select.connect("item_selected", self, "load_level")
	repopulate_levels()
	level_select.select(game.current_level)
	
	# Initialize chapter select.
	chapter_select.connect("item_selected", self, "load_chapter")
	repopulate_chapters()
	chapter_select.select(game.current_chapter)
	
	# Load current level.
	load_level(game.current_level)
	input.grab_focus()
	
func _process(delta):
	if _hint_server.is_connection_available():
		_hint_client_connection = _hint_server.take_connection()
		var length = _hint_client_connection.get_u32()
		var message = _hint_client_connection.get_string(length)
		game.notify(message)
		

func load_chapter(id):
	game.current_chapter = id
	repopulate_levels()
	load_level(0)

func load_level(level_id):
	next_level_button.hide()
	level_congrats.hide()
	level_description.show()
	game.current_level = level_id
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	
	levels.chapters[game.current_chapter].levels[game.current_level].construct()

	var level = levels.chapters[game.current_chapter].levels[game.current_level]
	level_description.bbcode_text = level.description[0]
	level_congrats.bbcode_text = level.congrats
	level_name.text = level.title
	if levels.chapters[game.current_chapter].levels[game.current_level].cards.size() == 0:
		cards.redraw_all_cards()
	else:
		cards.draw(levels.chapters[game.current_chapter].levels[game.current_level].cards)
	
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
			file_browser.repository = new_repo
			file_browser.update()
		repositories_node.add_child(new_repo)		
		repositories[r] = new_repo
	
	terminal.repository = repositories[repo_names[repo_names.size()-1]]
	terminal.clear()
	terminal.find_node("TextEditor").close()
	
	update_repos()
	
	# Unmute the audio after a while, so that player can hear pop sounds for
	# nodes they create.
	var t = Timer.new()
	t.wait_time = 1
	add_child(t)
	t.start()
	yield(t, "timeout")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	# FIXME: Need to clean these up when switching levels somehow.
	
	chapter_select.select(game.current_chapter)
	level_select.select(game.current_level)
	

func reload_level():
	cards.load_card_store()
	levels.reload()
	load_level(game.current_level)

func load_next_level():
	game.current_level = (game.current_level + 1) % levels.chapters[game.current_chapter].levels.size()
	load_level(game.current_level)
	
func show_win_status(win_states):
	var all_won = true
	var win_text = "\n\n"
	for state in win_states:
		win_text += "%s: %s\n" % [state, win_states[state]]
		if not win_states[state]:
			all_won = false
	var level = levels.chapters[game.current_chapter].levels[game.current_level]
	level_description.bbcode_text = level.description[0] + win_text
	for i in range(1,level.tipp_level+1):
		level_description.bbcode_text += level.description[i]
			
	if not level_congrats.visible and all_won and win_states.size() > 0:
		next_level_button.show()
		level_description.hide()
		level_congrats.show()
		$SuccessSound.play()

func repopulate_levels():
	levels.reload()
	level_select.clear()
	for level in levels.chapters[game.current_chapter].levels:
		level_select.add_item(level.title)
	level_select.select(game.current_level)

func repopulate_chapters():
	levels.reload()
	chapter_select.clear()
	for c in levels.chapters:
		chapter_select.add_item(c.slug)
	chapter_select.select(game.current_chapter)

func update_repos():
	var win_states = levels.chapters[game.current_chapter].levels[game.current_level].check_win()
	show_win_status(win_states)
	
	for r in repositories:
		var repo = repositories[r]
		repo.update_everything()
	file_browser.update()

func toggle_cards():
	cards.visible = not cards.visible
	
func new_tip():
	var level = levels.chapters[game.current_chapter].levels[game.current_level]
	if level.description.size() - 1 > level.tipp_level :
		level.tipp_level += 1
		level_description.bbcode_text += level.description[level.tipp_level]

func back():
	get_tree().change_scene("res://scenes/level_select.tscn")
