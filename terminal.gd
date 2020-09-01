extends Node2D

var thread

func send_command(command):
	thread = Thread.new()
	thread.start(self, "run_command_in_a_thread", command)

func run_command_in_a_thread(command):
	var output = game.sh(command, "/tmp/active")
	
	$Input.text = ""
	$Output.text = $Output.text + "$ " + command + "\n" + output
	$Output.scroll_vertical = 999999
	$"../ActiveRepository".update_everything()
