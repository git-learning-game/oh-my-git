extends Control

var thread

var history = []
var history_position = 0

onready var input = $Control/Input
onready var output = $Control/Output
onready var repo = $"../Repositories/ActiveRepository"
onready var main = get_parent()

func _ready():
	repo.shell.connect("output", self, "receive_output")

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

func send_command(command):
	history.push_back(command)
	history_position = history.size()
	
	input.editable = false
	
	if thread != null:
		thread.wait_to_finish()
	thread = Thread.new()
	thread.start(self, "run_command_in_a_thread", command)

func send_command_async(command):
	repo.shell.run_async(command)
	input.text = ""

func run_command_in_a_thread(command):
	var o = repo.shell.run(command)
	check_win_condition()
	
	input.text = ""
	input.editable = true
	output.text = output.text + "$ " + command + "\n" + o
	repo.update_everything() 

func receive_output(text):
	output.text += text

func clear():
	input.text = ""
	output.text = ""
	
func check_win_condition():
	if repo.shell.run("bash /tmp/win 2>&1 >/dev/null && echo yes || echo no") == "yes\n":
		main.show_win_status()
