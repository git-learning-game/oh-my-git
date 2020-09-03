extends Control

var thread

var history = []
var history_position = 0

onready var input = $Control/Input
onready var output = $Control/Output

func _input(event):
	if history.size() > 0:
		if event.is_action_pressed("ui_up"):
			history_position -= 1
			history_position %= history.size()
			input.text = history[history_position]
		if event.is_action_pressed("ui_down"):
			history_position += 1
			history_position %= history.size()
			input.text = history[history_position]

func send_command(command):
	history.push_back(command)
	history_position += 1
	
	thread = Thread.new()
	thread.start(self, "run_command_in_a_thread", command)

func run_command_in_a_thread(command):
	var o = game.sh(command, "/tmp/active")
	
	input.text = ""
	output.text = output.text + "$ " + command + "\n" + o
	output.scroll_vertical = 999999
	$"../Repositories/ActiveRepository".update_everything() # FIXME
