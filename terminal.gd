extends Node2D

var thread

var history = []
var history_position = 0

func _input(event):
	if history.size() > 0:
		if event.is_action_pressed("ui_up"):
			history_position -= 1
			history_position %= history.size()
			$Input.text = history[history_position]
		if event.is_action_pressed("ui_down"):
			history_position += 1
			history_position %= history.size()
			$Input.text = history[history_position]

func send_command(command):
	history.push_back(command)
	history_position += 1
	
	thread = Thread.new()
	thread.start(self, "run_command_in_a_thread", command)

func run_command_in_a_thread(command):
	var output = game.sh(command, "/tmp/active")
	
	$Input.text = ""
	$Output.text = $Output.text + "$ " + command + "\n" + output
	$Output.scroll_vertical = 999999
	$"../ActiveRepository".update_everything()
