extends Node2D

func _ready():
	pass



func send_command(new_text):
	var parts = new_text.split(" ")
	var cmd = parts[0]
	var args = parts
	args.remove(0)
	var output = []
	OS.execute(cmd, args, true, output, true)
	$Input.text = ""
	$Output.text = $Output.text + "$ " + new_text + "\n" + output[0]
	$Output.scroll_vertical = 999999
