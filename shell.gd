extends Node
class_name Shell

var _cwd

func _init():
	pass
	
func cd(dir):
	_cwd = dir

# Run a shell command given as a string. Run this if you're interested in the
# output of the command.
func run(command):
	var debug = false
	
	if debug:
		print("$ %s" % command)
	
	var env = {}
	env["EDITOR"] = game.cwd+"/scripts/fake-editor"
	env["TEST"] = "hi"
	
	var hacky_command = ""
	for variable in env:
		hacky_command += "export %s='%s';" % [variable, env[variable]]
	hacky_command += "cd '%s';" % _cwd
	hacky_command += command
	
	var output = game.exec("/bin/sh", ["-c",  hacky_command])
	
	if debug:
		print(output)
	
	return output
