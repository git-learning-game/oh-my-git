extends Control

signal command_done

var history_position = 0
var git_commands = ["add", "am", "archive", "bisect", "branch", "bundle", "checkout", "cherry-pick", "citool", "clean", "clone", "commit", "describe", "diff", "fetch", "format-patch", "gc", "gitk", "grep", "gui", "init", "log", "merge", "mv", "notes", "pull", "push", "range-diff", "rebase", "reset", "restore", "revert", "rm", "shortlog", "show", "sparse-checkout", "stash", "status", "submodule", "switch", "tag", "worktree", "config", "fast-export", "fast-import", "filter-branch", "mergetool", "pack-refs", "prune", "reflog", "remote", "repack", "replace", "annotate", "blame", "bugreport", "count-objects", "difftool", "fsck", "gitweb", "help", "instaweb", "merge-tree", "rerere", "show-branch", "verify-commit", "verify-tag", "whatchanged", "archimport", "cvsexportcommit", "cvsimport", "cvsserver", "imap-send", "p", "quiltimport", "request-pull", "send-email", "svn", "apply", "checkout-index", "commit-graph", "commit-tree", "hash-object", "index-pack", "merge-file", "merge-index", "mktag", "mktree", "multi-pack-index", "pack-objects", "prune-packed", "read-tree", "symbolic-ref", "unpack-objects", "update-index", "update-ref", "write-tree", "cat-file", "cherry", "diff-files", "diff-index", "diff-tree", "for-each-ref", "get-tar-commit-id", "ls-files", "ls-remote", "ls-tree", "merge-base", "name-rev", "pack-redundant", "rev-list", "rev-parse", "show-index", "show-ref", "unpack-file", "var", "verify-pack", "daemon", "fetch-pack", "http-backend", "send-pack", "update-server-info", "check-attr", "check-ignore", "check-mailmap", "check-ref-format", "column", "credential", "credential-cache", "credential-store", "fmt-merge-msg", "interpret-trailers", "mailinfo", "mailsplit", "merge-one-file", "patch-id", "sh-i", "sh-setup"]

var git_commands_help = []

onready var input = $Rows/InputLine/Input
onready var output = $Rows/TopHalf/Output
onready var completions = $Rows/TopHalf/Completions
var repository
onready var main = get_tree().get_root().get_node("Main")

var shell = Shell.new()

var premade_commands = [
	'git commit --allow-empty -m "empty"',
	'echo $RANDOM | git hash-object -w --stdin',
	'git switch -c $RANDOM',
]

func _ready():
	var error = $TextEditor.connect("hide", self, "editor_closed")
	if error != OK:
		helpers.crash("Could not connect TextEditor's hide signal")
	input.grab_focus()

	for subcommand in git_commands:
		git_commands_help.push_back("")
	
	completions.hide()
	history_position = game.state["history"].size()

func _input(event):
	if not input.has_focus():
		return

	if game.state["history"].size() > 0:
		if event.is_action_pressed("ui_up"):
			if history_position > 0:
				history_position -= 1
				input.text = game.state["history"][history_position]
				input.caret_position = input.text.length()
			# This prevents the Input taking the arrow as a "skip to beginning" command.
			get_tree().set_input_as_handled()
		if event.is_action_pressed("ui_down"):
			if history_position < game.state["history"].size()-1:
				history_position += 1
				input.text = game.state["history"][history_position]
				input.caret_position = input.text.length()
			get_tree().set_input_as_handled()
			
	if event.is_action_pressed("tab_complete"):
		if completions.visible:
			completions.get_root().get_children().select(0)
		get_tree().set_input_as_handled()
	if event.is_action_pressed("delete_word"):
		var first_half = input.text.substr(0,input.caret_position)
		var second_half = input.text.substr(input.caret_position)
		
		var idx = first_half.strip_edges(false, true).find_last(" ")
		if idx > 0:
			input.text = first_half.substr(0,idx+1) + second_half
			input.caret_position = idx+1
		else:
			input.text = "" + second_half
	if event.is_action_pressed("clear"):
		clear()
		
func load_command(id):
	input.text = premade_commands[id]
	input.caret_position = input.text.length()

func send_command(command):
	close_all_editors()
	game.state["history"].push_back(command)
	game.save_state()
	history_position = game.state["history"].size()
	
	input.editable = false
	completions.hide()

	# If someone tries to run an editor, use fake-editor instead.
	var editor_regex = RegEx.new()
	editor_regex.compile("^(vim?|gedit|emacs|kate|nano|code) ")
	command = editor_regex.sub(command, "fake-editor ")

	shell.cd(repository.path)
	var cmd = shell.run_async(command, false)
	yield(cmd, "done")
	call_deferred("command_done", cmd)

func command_done(cmd):
	if cmd.exit_code == 0:
		$OkSound.pitch_scale = rand_range(0.8, 1.2)
		$OkSound.play()
	else:
		$ErrorSound.play()
	
	input.text = ""
	input.editable = true
	
	if cmd.output.length() <= 1000:
		output.text = output.text + "$ " + cmd.command + "\n" + cmd.output
		game.notify("This is your terminal! All commands are executed here, and you can see their output. You can also type your own commands here!", self, "terminal")
	else:
		$Pager/Text.text = cmd.output
		$Pager.popup()
	
	emit_signal("command_done")
	
func receive_output(text):
	output.text += text
	repository.update_everything()

func clear():
	output.text = ""
	
func editor_closed():
	input.grab_focus()
		
func regenerate_completions_menu(new_text):
	var comp = generate_completions(new_text)
	
	completions.clear()
	
	
	var filtered_comp = []
	for c in comp:
		if c != new_text:
			filtered_comp.push_back(c)
	
	if filtered_comp.size() == 0:
		completions.hide()
	else:
		completions.show()
	
		var _root = completions.create_item()
		for c in filtered_comp:
			var child = completions.create_item()
			child.set_text(0, c)
			if c.split(" ").size() >= 2:
				var subcommand = c.split(" ")[1]
				var idx = git_commands.find(subcommand)
				if idx >= 0:
					child.set_text(1, git_commands_help[idx])
					
		completions.margin_top = -min(filtered_comp.size() * 35 + 10, 210) 

func relevant_subcommands():
	var result = {}
	for h in game.state["history"]:
		var parts = Array(h.split(" "))
		if parts.size() >= 2 and parts[0] == "git":
			var subcommand = parts[1]
			if git_commands.has(subcommand):
				if not result.has(subcommand):
					result[subcommand] = 0
				result[subcommand] += 1
	
	# Convert to format [["add", 3], ["pull", 5]].
	var result_array = []
	for r in result:
		result_array.push_back([r, result[r]])
	
	result_array.sort_custom(self, "sort_by_frequency_desc")
	
	var plain_result = []
	for r in result_array:
		plain_result.push_back(r[0])
	return plain_result

func sort_by_frequency_desc(a, b):
	return a[1] > b[1]
	
func generate_completions(command):
	var results = []
	
	# Collect git commands.
	if command.substr(0, 4) == "git ":
		var rest = command.substr(4)
		var subcommands = relevant_subcommands()
		
		for sc in subcommands:
			if sc.substr(0, rest.length()) == rest:
				results.push_back("git "+sc)
	
	# Part 1: Only autocomplete after git subcommand.
	# Part2: Prevent autocompletion to only show filename at the beginning of a command.
	if !(command.substr(0,4) == "git " and command.split(" ").size() <= 2) and command.split(" ").size() > 1:
		var last_word = Array(command.split(" ")).pop_back()
		var file_string = repository.shell.run("find . -type f")
		var files = file_string.split("\n")
		files = Array(files)
		# The last entry is an empty string, remove it.
		files.pop_back()
		for file_path in files:
			file_path = file_path.substr(2)
			if file_path.substr(0,4) != ".git" and file_path.substr(0,last_word.length()) == last_word:
				results.push_back(command+file_path.substr(last_word.length()))
	
	return results

func _input_changed(new_text):
	call_deferred("regenerate_completions_menu", new_text)

func _completion_selected():
	var item = completions.get_selected()
	input.text = item.get_text(0)
	input.emit_signal("text_changed", input.text)
	#completions.hide()
	input.grab_focus()
	input.caret_position = input.text.length()

func editor_saved():
	emit_signal("command_done")

func close_all_editors():
	for editor in get_tree().get_nodes_in_group("editors"):
		editor.close()
