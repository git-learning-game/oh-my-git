extends Node

var tmp_prefix = _tmp_prefix()
var global_shell
var debug_file_io = false
var fake_editor

func _ready():
	global_shell = Shell.new()
	
	# Copy fake-editor to tmp directory (because the original might be in a .pck file).
	var fake_editor_outside = tmp_prefix + "fake-editor"
	fake_editor = "/tmp/fake-editor"
	var content = game.read_file("res://scripts/fake-editor", "")
	if content.empty():
		push_error("fake-editor could not be read.")
	write_file(fake_editor_outside, content)
	global_shell.run("chmod u+x " + fake_editor)

func read_file(path, fallback_string):
	if debug_file_io:
		print("reading " + path)
	var file = File.new()
	var open_status = file.open(path, File.READ)
	if open_status == OK:
		var content = file.get_as_text()
		file.close()
		return content
	else:
		return fallback_string

func write_file(path, content):
	if debug_file_io:
		print("writing " + path)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()
	return true

func _tmp_prefix():
	var os = OS.get_name()
	if os == "X11":
		return "/tmp/"
	elif os == "Windows":
		# For some reason, this command outputs a space in the end? We remove it.
		# Also, Godot's default is to use forward slashes for everything.
		return exec("echo", ["%TEMP%"]).replacen("\\", "/").replace(" \n", "/")
	else:
		push_error("Unsupported OS")
		get_tree().quit()

# Run a simple command with arguments, blocking, using OS.execute.
func exec(command, args=[]):
	var debug = false
	
	if debug:
		print("exec: %s [%s]" % [command, PoolStringArray(args).join(", ")])
		
	var output = []
	var exit_code = OS.execute(command, args, true, output, true)
	output = output[0]
	
	if exit_code != 0:
		push_error("OS.execute failed: %s [%s] Output: %s" % [command, PoolStringArray(args).join(", "), output])
	
	if debug:
		print(output)

	return output
