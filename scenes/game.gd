extends Node

var tmp_prefix = OS.get_user_data_dir() + "/tmp/"
var global_shell
var fake_editor

var dragged_object
var energy = 2
var used_cards = false

var current_chapter = 0
var current_level = 0
var skipped_title = false

var translations = {}
var current_locale = "en"

var _file = "user://savegame.json"
var state = {}

var mutex

func _ready():
	mutex = Mutex.new()
	load_state()
	
	TranslationServer.set_locale("en")
	
	if OS.has_feature("standalone"):
		get_tree().set_auto_accept_quit(false)
	else:
		game.toggle_music()
	
	if OS.get_name() == "Windows":
		start_remote_shell()
	global_shell = new_shell()
	
#	var cmd = global_shell.run("echo hi")
#	print(cmd)
#	cmd = global_shell.run("seq 1 10")
#	print(cmd)
#	cmd = global_shell.run("ls")
#	print(cmd)
#	helpers.crash(":)")

	if global_shell.run("command -v git &>/dev/null && echo yes || echo no") == "no\n":
		game.skipped_title = true
		get_tree().change_scene("res://scenes/no_git.tscn")
	else:
		create_file_in_game_env(".gitconfig", helpers.read_file("res://scripts/gitconfig"))
		
		copy_script_to_game_env("fake-editor")
		copy_script_to_game_env("hint")

func start_remote_shell():
	var user_dir = ProjectSettings.globalize_path("user://")
	var script_content = helpers.read_file("res://scripts/net-test")
	var target_filename = user_dir + "net-test"
	var target_file = File.new()
	target_file.open(target_filename, File.WRITE)
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
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		#get_tree().quit() # default behavior
		get_tree().change_scene("res://scenes/survey.tscn")
		

func copy_script_to_game_env(name):
	create_file_in_game_env(name, helpers.read_file("res://scripts/%s" % name))
	global_shell.run("chmod u+x '%s'" % (tmp_prefix + name))
	
func _initial_state():
	return {"history": [], "solved_levels": [], "received_hints": [], "cli_badge": [], "played_cards": []}
	
func save_state():
	var savegame = File.new()
	
	savegame.open(_file, File.WRITE)
	savegame.store_line(to_json(state))
	savegame.close()
	
func load_state():
	var savegame = File.new()
	if not savegame.file_exists(_file):
		save_state()
	
	savegame.open(_file, File.READ)
	
	state = _initial_state()
	var new_state = parse_json(savegame.get_line())
	for key in new_state:
		state[key] = new_state[key]
	savegame.close()
	
# filename is relative to the tmp directory!
func create_file_in_game_env(filename, content):
	global_shell.cd(tmp_prefix)
	# Quoted HERE doc doesn't do any substitutions inside.
	global_shell.run("cat > '%s' <<'HEREHEREHERE'\n%s\nHEREHEREHERE" % [filename, content])

func notify(text, target=null, hint_slug=null):
	if hint_slug:
		if not state.has("received_hints"):
			state["received_hints"] = []
		if hint_slug in state["received_hints"]:
			return
		
	var notification = preload("res://scenes/notification.tscn").instance()
	notification.text = text
	if not target:
		target = get_tree().root
	target.call_deferred("add_child", notification)
	
	if hint_slug:
		state["received_hints"].push_back(hint_slug)
		save_state()
		
func open_survey():
	OS.shell_open("https://patreon.com/bleeptrack")
	OS.shell_open("https://patreon.com/blinry")
	
func toggle_music():
	var music = game.find_node("Music")
	if music.volume_db > -20:
		music.volume_db -= 100
	else:
		music.volume_db += 100

func shell_test(command):
	mutex.lock()
	#print("go")
	#print(command)
	var before = OS.get_ticks_msec()
	
	while not $ShellServer._connected:
		$ShellServer._process(0.1)
	
	var response = $ShellServer.send(command)
	var after = OS.get_ticks_msec()
	#print("took " + str(after-before)+" ms")
	#print("stop")
	mutex.unlock()
	return response
	
func new_shell():
	if OS.get_name() == "Windows":
		return BetterShell.new()
	else:
		return Shell.new()

# --- ДОБАВИТЬ ЭТИ ДВЕ ФУНКЦИИ В КОНЕЦ ФАЙЛА ---

# Загружает наш CSV в словарь для быстрого доступа
func _load_translations():
	var file = File.new()
	if not file.file_exists("res://translations.csv"):
		print_debug("Локализация: Файл translations.csv не найден.")
		return
		
	file.open("res://translations.csv", File.READ)
	var headers = file.get_csv_line() # Пропускаем первую строку с заголовками
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		# Проверяем, что в строке есть все нужные столбцы
		if line != null and line.size() >= 3:
			var key = line[0]
			var en_text = line[1]
			var ru_text = line[2]
			translations[key] = {"en": en_text, "ru": ru_text}
	file.close()

# Наша собственная функция перевода
# Улучшенная, "безопасная" версия функции
func tr_custom(key):
	# Если ключ - это не строка, всегда возвращаем ПУСТУЮ СТРОКУ, а не Nil.
	if typeof(key) != TYPE_STRING:
		return ""

	if translations.has(key) and translations[key].has(current_locale):
		var translated_text = translations[key][current_locale]
		# Эта проверка гарантирует, что мы не вернем null/Nil
		if translated_text != null and translated_text != "":
			return translated_text
		# Если перевод пустой, возвращаем английский текст
		var en_text = translations[key]["en"]
		return en_text if en_text != null else ""
		
	# Если ключ не найден, возвращаем сам ключ (или пустую строку, если ключ пустой)
	return key if key != null else ""
	
func _init():
	# --- ПРИВЕСТИ ФУНКЦИЮ _init() К ТАКОМУ ВИДУ ---
	_load_translations()
	current_locale = "en"
