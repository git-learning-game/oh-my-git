extends Node
class_name Shell

var _cwd
var _fake_editor

func _init():
	# Copy fake-editor to tmp directory (because the original might be in a .pck file).
	_fake_editor = game.tmp_prefix + "fake-editor"
	var content = game.read_file("res://scripts/fake-editor")
	game.write_file(_fake_editor, content)
	run("chmod u+x " + _fake_editor)
	
func cd(dir):
	_cwd = dir

# Run a shell command given as a string. Run this if you're interested in the
# output of the command.
func run(command):
	var debug = false
	
	if debug:
		print("$ %s" % command)
	
	var env = {}
	env["EDITOR"] = _fake_editor
	
	var hacky_command = ""
	for variable in env:
		hacky_command += "export %s='%s';" % [variable, env[variable]]
	hacky_command += "cd '%s';" % _cwd
	hacky_command += command
	
	var output = game.exec("/bin/sh", ["-c",  hacky_command])
	
	if debug:
		print(output)
	
	return output
