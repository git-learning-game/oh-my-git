extends Node

var cwd

func _ready():
	cwd = exec("pwd", [], true)

# Run a simple command with arguments, blocking, using OS.execute.
func exec(command, args=[], remote_trailing_newline=false):
	var debug = false
	if debug:
		print("game.exec: %s [%s]" % [command, PoolStringArray(args).join(", ")])
		
	var output = []
	OS.execute(command, args, true, output, true)
	output = output[0]
	
	if debug:
		print(output)
	
	if remote_trailing_newline:
		output = output.substr(0,len(output)-1)
		
	return output

func read_file(path):
	print("read "+path)
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_as_text()
	file.close()
	return content

func write_file(path, content):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()
	return true
