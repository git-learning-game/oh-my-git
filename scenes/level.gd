extends Node
class_name Level

var slug
var title
var description
var congrats
var cards
var repos = {}
var tipp_level = 0


# The path is an outer path.
func load(path):
	var parts = path.split("/")
	slug = parts[parts.size()-1]
	
	var dir = Directory.new()
	if dir.file_exists(path):
		# This is a new-style level.
		var config = helpers.parse(path)
		
		# --- НАЧАЛО БЛОКА ЛОКАЛИЗАЦИИ ---
		# 1. Сначала получаем КЛЮЧИ из файла уровня.
		#    "default_..." - это запасные ключи, если в файле уровня чего-то нет.
		var title_key = config.get("title", "default_title_key")
		var description_key = config.get("description", "default_description_key")
		var congrats_key = config.get("congrats", "default_congrats_key")
		
		# 2. Теперь ПЕРЕВОДИМ ключи с помощью нашего глобального переводчика из game.gd.
		title = game.tr_custom(title_key)
		var description_text = game.tr_custom(description_key)
		congrats = game.tr_custom(congrats_key)
		# --- КОНЕЦ БЛОКА ЛОКАЛИЗАЦИИ ---

		# 3. Дальше идет оригинальная обработка УЖЕ ПЕРЕВЕДЕННОГО текста description.
		var monospace_regex = RegEx.new()
		monospace_regex.compile("\\n    ([^\\n]*)")
		description_text = monospace_regex.sub(description_text, "\n      [code][color=#e1e160]$1[/color][/code]", true)
		description = description_text.split("---")
		
		var cli_hints = config.get("cli", "")
		# Also do this substitution in the CLI hints.
		cli_hints = monospace_regex.sub(cli_hints, "\n      [code][color=#bbbb5d]$1[/color][/code]", true)
		
		# Also replace `code` with [code] tags.
		var monospace_inline_regex = RegEx.new()
		monospace_inline_regex.compile("`([^`]+)`")
		description[0] = monospace_inline_regex.sub(description[0], "[code][color=#e1e160]$1[/color][/code]")
		cli_hints = monospace_inline_regex.sub(cli_hints, "[code][color=#bbbb5d]$1[/color][/code]", true)
		
		if cli_hints != "":
			description[0] = description[0] + "\n\n[color=#787878]"+cli_hints+"[/color]"
		
		# Этот код остается без изменений, так как он не работает с переводимым текстом
		cards = Array(config.get("cards", "").split(" "))
		if cards == [""]:
			cards = []
		
		var keys = config.keys()
		var repo_setups = []
		for k in keys:
			if k.begins_with("setup"):
				repo_setups.push_back(k)
		var repo_wins = []
		for k in keys:
			if k.begins_with("win"):
				repo_wins.push_back(k)
		var repo_actions = []
		for k in keys:
			if k.begins_with("actions"):
				repo_actions.push_back(k)
				
		for k in repo_setups:
			var repo
			if " " in k: # [setup yours]
				repo = Array(k.split(" "))[1]
			else:
				repo = "yours"
			if not repos.has(repo):
				repos[repo] = LevelRepo.new()
			repos[repo].setup_commands = config[k]
		
		for k in repo_wins:
			var repo
			if " " in k:
				repo = Array(k.split(" "))[1]
			else:
				repo = "yours"
			
			# Наш "защитный" код от ошибки, которую мы исправили ранее
			if not repos.has(repo):
				repos[repo] = LevelRepo.new()
			
			var desc = game.tr_custom(config.get("win_desc", "default_win_desc_key"))
			for line in Array(config[k].split("\n")):
				if line.length() > 0 and line[0] == "#":
					# --- ДОПОЛНИТЕЛЬНОЕ ИЗМЕНЕНИЕ: ПЕРЕВОДИМ ПОДСКАЗКИ В [WIN] ---
					var hint_key = line.substr(1).strip_edges(true, true)
					desc = game.tr_custom(hint_key)
				else:
					if not repos[repo].win_conditions.has(desc):
						repos[repo].win_conditions[desc] = ""
					repos[repo].win_conditions[desc] += line+"\n"
					
		for k in repo_actions:
			var repo
			if " " in k:
				repo = Array(k.split(" "))[1]
			else:
				repo = "yours"
			
			repos[repo].action_commands = config[k]
				
	else:
		helpers.crash("Level %s does not exist." % path)
	
	for repo in repos:
		repos[repo].path = game.tmp_prefix+"repos/%s/" % repo
		repos[repo].slug = repo
	

func construct():
	for r in repos:
		var repo = repos[r]
		# We're actually destroying stuff here.
		# Make sure that active_repository is in a temporary directory.
		helpers.careful_delete(repo.path)
		
		game.global_shell.run("mkdir '%s'" % repo.path)
		game.global_shell.cd(repo.path)
		game.global_shell.run("git init")
		game.global_shell.run("git symbolic-ref HEAD refs/heads/main")
		
		# Add other repos as remotes.
		for r2 in repos:
			if r == r2:
				continue
			game.global_shell.run("git remote add %s '%s'" % [r2, repos[r2].path])
		
	for r in repos:
		var repo = repos[r]
		game.global_shell.cd(repo.path)
		game.global_shell.run(repo.setup_commands)

func check_win():
	var win_states = {}
	for r in repos:
		var repo = repos[r]
		game.global_shell.cd(repo.path)
		if repo.action_commands.length() > 0:
			game.global_shell.run("function actions { %s\n}; actions 2>/dev/null >/dev/null || true" % repo.action_commands)
		if repo.win_conditions.size() > 0:
			for description in repo.win_conditions:
				var commands = repo.win_conditions[description]
				var won = game.global_shell.run("function win { %s\n}; win 2>/dev/null >/dev/null && echo yes || echo no" % commands) == "yes\n"
				win_states[description] = won		
	return win_states 
