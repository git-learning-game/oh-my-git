extends Node

var tmp_prefix = "/tmp/"
var global_shell

func _ready():
	global_shell = Shell.new()
	global_shell.cd(tmp_prefix)

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
