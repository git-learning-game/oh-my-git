extends Control

var thread

var history_position = 0
var git_commands = []
var git_commands_help = []

onready var input = $VBoxContainer/InputLine/Input
onready var output = $VBoxContainer/TopHalf/Output
onready var completions = $VBoxContainer/TopHalf/Completions
export(NodePath) var repository_path
onready var repository = get_node(repository_path)
onready var command_dropdown = $VBoxContainer/InputLine/CommandDropdown
onready var main = get_tree().get_root().get_node("Main")

var premade_commands = [
	'git commit --allow-empty -m "empty"',
	'echo $RANDOM | git hash-object -w --stdin',
	'git switch -c $RANDOM',
]

func _ready():
	#repository.shell.connect("output", self, "receive_output")

	for command in premade_commands:
		command_dropdown.get_popup().add_item(command)
	command_dropdown.get_popup().connect("id_pressed", self, "load_command")
	
	var error = $TextEditor.connect("hide", self, "editor_closed")
	if error != OK:
		push_error("Could not connect TextEditor's hide signal")
	input.grab_focus()
	
	var all_git_commands = repository.shell.run("git help -a | grep \"^ \\+[a-z-]\\+ \" -o")
	git_commands = Array(all_git_commands.split("\n"))
	for i in range(git_commands.size()):
		git_commands[i] = git_commands[i].strip_edges(true, true)
	git_commands.pop_back()
	
	var all_git_commands_help = repository.shell.run("git help -a | grep \"  [A-Z].\\+$\" -o")
	git_commands_help = Array(all_git_commands_help.split("\n"))
	for i in range(git_commands_help.size()):
		git_commands_help[i] = git_commands_help[i].strip_edges(true, true)
	git_commands_help.pop_back()
	
	completions.hide()
	history_position = game.state["history"].size()

func _input(event):
	#print(game.state)
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
		
func load_command(id):
	input.text = premade_commands[id]
	input.caret_position = input.text.length()

func send_command(command):
	game.state["history"].push_back(command)
	game.save_state()
	history_position = game.state["history"].size()
	
	input.editable = false
	completions.hide()
	
	if thread != null:
		thread.wait_to_finish()
	thread = Thread.new()
	thread.start(self, "run_command_in_a_thread", command)

func send_command_async(command):
	#output.text += "$ "+command+"\n"
	input.text = ""
	#repository.shell.run_async(command)
	$TCPServer.send(command+"\n")

func run_command_in_a_thread(command):
	var o = repository.shell.run(command)
	check_win_condition()
	
	input.text = ""
	input.editable = true
	output.text = output.text + "$ " + command + "\n" + o
	repository.update_everything()

func receive_output(text):
	output.text += text
	repository.update_everything()

func clear():
	output.text = ""
	
func editor_closed():
	input.grab_focus()
	
func check_win_condition():
	if repository.shell.run("bash /tmp/win 2>/dev/null >/dev/null && echo yes || echo no") == "yes\n":
		main.show_win_status()
		
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

func relevant_subcommands():
	var result = {}
	for h in game.state["history"]:
		var parts = Array(h.split(" "))
		if parts[0] == "git":
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
		var file_string = repository.shell.run("find -type f")
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
