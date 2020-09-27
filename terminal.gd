extends Control

var thread

var history = []
var history_position = 0
var git_commands = []

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
	
	var all_git_commands = repository.shell.run("git help -a | grep \"^ \\+[a-z-]\\+ \" -o | sed -e 's/^[ \t]*//'")
	git_commands = Array(all_git_commands.split("\n"))
	git_commands.pop_back()
	
	completions.hide()

func _input(event):
	if history.size() > 0:
		if event.is_action_pressed("ui_up"):
			if history_position > 0:
				history_position -= 1
				input.text = history[history_position]
				input.caret_position = input.text.length()
			# This prevents the Input taking the arrow as a "skip to beginning" command.
			get_tree().set_input_as_handled()
		if event.is_action_pressed("ui_down"):
			if history_position < history.size()-1:
				history_position += 1
				input.text = history[history_position]
				input.caret_position = input.text.length()
			get_tree().set_input_as_handled()

func load_command(id):
	input.text = premade_commands[id]
	input.caret_position = input.text.length()

func send_command(command):
	history.push_back(command)
	history_position = history.size()
	
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

func generate_completions(command):
	if command.substr(0, 4) == "git ":
		var rest = command.substr(4)
		var subcommands = git_commands
		
		var results = []
		for sc in subcommands:
			if sc.substr(0, rest.length()) == rest:
				results.push_back("git "+sc)
				
		return results
	return []

func _input_changed(new_text):
	call_deferred("regenerate_completions_menu", new_text)

func _completion_selected():
	var item = completions.get_selected()
	input.text = item.get_text(0)
	input.emit_signal("text_changed", input.text)
	#completions.hide()
	input.grab_focus()
	input.caret_position = input.text.length()
