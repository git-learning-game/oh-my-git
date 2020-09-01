extends Node2D

var thread

func send_command(command):
	thread = Thread.new()
	thread.start(self, "run_command_in_a_thread", command)

func run_command_in_a_thread(command):
	var cwd = run("pwd")
	var output = []
	
	var hacky_command = command
	hacky_command = "cd /tmp/githydragit;"+hacky_command
	hacky_command = "export EDITOR=fake-editor;"+hacky_command
	hacky_command = "export PATH=\"$PATH\":"+cwd+"/scripts;"+hacky_command
	OS.execute("/bin/sh", ["-c",  hacky_command], true, output, true)
	
	$Input.text = ""
	$Output.text = $Output.text + "$ " + command + "\n" + output[0]
	$Output.scroll_vertical = 999999
	
func run(command):
	var output = []
	OS.execute(command, [], true, output, true)
	# Remove trailing newline.
	return output[0].substr(0,len(output[0])-1)
