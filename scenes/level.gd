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
		
		title = translate_string(config.get("title", slug))
		var description_text = translate_string(config.get("description", "_((no description))"))
		congrats = translate_string(config.get("congrats", "_(Good job, you solved the level!\n\nFeel free to try a few more things or click 'Next level'.)"))

		var cli_hints = translate_string(config.get("cli", ""))

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
		
		if cli_hints != null and cli_hints != "":
			cli_hints = monospace_regex.sub(cli_hints, "\n      [code][color=#bbbb5d]$1[/color][/code]", true)
			cli_hints = monospace_inline_regex.sub(cli_hints, "[code][color=#bbbb5d]$1[/color][/code]", true)
			if description.size() > 0:
				description[0] = description[0] + "\n\n[color=#787878]"+cli_hints+"[/color]"

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
			repos[repo].setup_commands = translate_string(config[k])

		for k in repo_wins:
			var repo
			if " " in k:
				repo = Array(k.split(" "))[1]
			else:
				repo = "yours"
			
			if not repos.has(repo):
				repos[repo] = LevelRepo.new()
	
			var desc = translate_string(config.get("win_desc", "Complete the goal of this level"))
			for line in Array(config[k].split("\n")):
				if line.length() > 0 and line[0] == "#":
					var hint_key = line.substr(1).strip_edges(true, true)
					desc = translate_string(hint_key)
				else:
					var translated_line = translate_string(line)
					if not repos[repo].win_conditions.has(desc):
						repos[repo].win_conditions[desc] = ""
					repos[repo].win_conditions[desc] += translated_line+"\n"
					
		for k in repo_actions:
			var repo
			if " " in k:
				repo = Array(k.split(" "))[1]
			else:
				repo = "yours"
			
			repos[repo].action_commands = translate_string(config[k])
				
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

func translate_string(text):
	if typeof(text) != TYPE_STRING:
		return text

	var result = ""
	var i = 0
	var length = text.length()

	while i < length:
		if text.substr(i, 2) == "_(":
			var content_start = i + 2
			var current = content_start
			var depth = 1
			var found_end = false

			while current < length:
				var char_at = text[current]

				if char_at == "\\":
					current += 2
					continue

				if char_at == "(":
					depth += 1
				elif char_at == ")":
					depth -= 1

				if depth == 0:
					found_end = true
					break

				current += 1

			if found_end:
				var key = text.substr(content_start, current - content_start)

				key = key.replace("\\)", ")").replace("\\(", "(")

				result += tr(key)
				i = current + 1
			else:
				result += text[i]
				i += 1
		else:
			result += text[i]
			i += 1

	return result
