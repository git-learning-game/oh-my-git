extends Node

var tmp_prefix = "/tmp/"
var cwd
var global_shell

func _ready():
	global_shell = Shell.new()
	global_shell.cd(tmp_prefix)
	
	cwd = global_shell.run("pwd")
	# Remove trailing newline.
	cwd = cwd.substr(0,len(cwd)-1)

# Run a simple command with arguments, blocking, using OS.execute.
func exec(command, args=[]):
	var debug = true
	if debug:
		print("game.exec: %s [%s]" % [command, PoolStringArray(args).join(", ")])
		
	var output = []
	OS.execute(command, args, true, output, true)
	output = output[0]
	
	if debug:
		print(output)

	return output

func read_file(path):
	print ("reading " + path)
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_as_text()
	file.close()
	return content

func write_file(path, content):
	print ("writing " + path)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()
	return true
