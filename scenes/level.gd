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
		var config = helpers.parse(path)
		
		title = tr(config.get("title", "default_title_key"))
		var description_text = tr(config.get("description", "default_description_key"))
		congrats = tr(config.get("congrats", "default_congrats_key"))

		var cli_hints_keys_block = config.get("cli", "")
		var translated_cli_lines = []
		
		if cli_hints_keys_block != "":
			for key in cli_hints_keys_block.split("\n"):
				var stripped_key = key.strip_edges(true, true)
				if stripped_key != "":
					translated_cli_lines.push_back(tr(stripped_key))
				else:
					translated_cli_lines.push_back("")
		
		var cli_hints_text = PoolStringArray(translated_cli_lines).join("\n")
		var monospace_regex = RegEx.new()
		monospace_regex.compile("\\n    ([^\\n]*)")
		var monospace_inline_regex = RegEx.new()
		monospace_inline_regex.compile("`([^`]+)`")

		if description_text != null:
			description_text = monospace_regex.sub(description_text, "\n      [code][color=#e1e160]$1[/color][/code]", true)
			description_text = monospace_inline_regex.sub(description_text, "[code][color=#e1e160]$1[/color][/code]")
		else:
			description_text = ""
		
		description = description_text.split("---")
		
		if cli_hints_text != null and cli_hints_text != "":
			cli_hints_text = monospace_regex.sub(cli_hints_text, "\n      [code][color=#bbbb5d]$1[/color][/code]", true)
			cli_hints_text = monospace_inline_regex.sub(cli_hints_text, "[code][color=#bbbb5d]$1[/color][/code]", true)
			if description.size() > 0:
				description[0] = description[0] + "\n\n[color=#787878]"+cli_hints_text+"[/color]"
				
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
			
			if not repos.has(repo):
				repos[repo] = LevelRepo.new()
			
			var desc = tr(config.get("win_desc", "default_win_desc_key"))
			for line in Array(config[k].split("\n")):
				if line.length() > 0 and line[0] == "#":
					var hint_key = line.substr(1).strip_edges(true, true)
					desc = tr(hint_key)
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
