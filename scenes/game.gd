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

var available_languages = []
var current_language

var _file = "user://savegame.json"
var state = {}

var mutex

func _ready():
	mutex = Mutex.new()
	load_state()
	
	if OS.has_feature("standalone"):
		get_tree().set_auto_accept_quit(false)
	else:
		game.toggle_music()
	
	if OS.get_name() == "Windows":
		start_remote_shell()
	global_shell = new_shell()
	
	_load_translations()
	_set_initial_language()
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

func _load_translations():
	var file = File.new()
	var path = "res://translations.csv"
	
	if not file.file_exists(path):
		printerr("ЛОКАЛИЗАЦИЯ (ОШИБКА): Файл %s не найден." % path)
		return
	
	file.open(path, File.READ)
	
	# ★ Читаем заголовок, чтобы узнать, какие языки есть в CSV
	var header = file.get_csv_line()
	# header = ["key", "en", "ru", "de", ...]
	
	if header.size() < 2:
		printerr("ЛОКАЛИЗАЦИЯ (ОШИБКА): Некорректный формат CSV.")
		file.close()
		return
	
	# ★★ Создаем словарь: язык → объект Translation
	var translations_map = {}
	
	# Пропускаем первую колонку (это "key"), остальные — языки
	for i in range(1, header.size()):
		var locale = header[i].strip_edges()  # "en", "ru", "de"...
		
		if locale == "":
			continue
		
		available_languages.append(locale)
		
		# Создаем Translation для каждого языка
		var translation = Translation.new()
		translation.set_locale(locale)
		translations_map[locale] = translation
	
	print_debug("ЛОКАЛИЗАЦИЯ: Найдены языки: %s" % str(available_languages))
	
	# ★★★ Читаем все строки и заполняем переводы для ВСЕХ языков
	var loaded_keys = 0
	while not file.eof_reached():
		var line = file.get_csv_line()
		
		if line == null or line.size() < 2 or line[0].strip_edges() == "":
			continue
		
		var key = line[0].strip_edges()
		
		# Для каждого языка добавляем перевод
		for i in range(1, min(line.size(), header.size())):
			var locale = header[i].strip_edges()
			var translated_text = line[i]
			
			if translations_map.has(locale):
				translations_map[locale].add_message(key, translated_text)
		
		loaded_keys += 1
	
	file.close()
	
	# ★★★★ Регистрируем ВСЕ переводы в TranslationServer
	for locale in translations_map.keys():
		TranslationServer.add_translation(translations_map[locale])
		print_debug("ЛОКАЛИЗАЦИЯ: Загружено %d ключей для языка '%s'" % [loaded_keys, locale])

func _set_initial_language():
	var system_language = OS.get_locale_language()  # Возвращает "ru", "en", "de"...

	if system_language in available_languages:
		current_language = system_language
	else:
		current_language = "en"
		
	TranslationServer.set_locale(current_language)
	
func get_available_languages() -> Array:
	return available_languages

func _update_all_ui():
	get_tree().reload_current_scene()

func change_language(new_language: String):
	if not new_language in available_languages:
		printerr("ЛОКАЛИЗАЦИЯ: Язык '%s' не поддерживается. Доступны: %s" % [new_language, str(available_languages)])
		return
	
	current_language = new_language
	TranslationServer.set_locale(new_language)
	
	_update_all_ui()
	
