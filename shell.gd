extends Node
class_name Shell

var _cwd
var _fake_editor

signal output(text)

func _init():
	# Copy fake-editor to tmp directory (because the original might be in a .pck file).
	_fake_editor = game.tmp_prefix + "fake-editor"
	var content = game.read_file("res://scripts/fake-editor")
	game.write_file(_fake_editor, content)
	_exec("chmod", ["u+x", _fake_editor])
	
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
	
	var output = _exec(_shell_binary(), ["-c",  hacky_command])
	
	if debug:
		print(output)
	
	return output
	
func _shell_binary():
	var os = OS.get_name()
	
	if os == "X11":
		return "/bin/sh"
	elif os == "Windows":
		return "external/git_bash.exe"
	else:
		push_error("Unsupported OS")
		get_tree().quit()

var _t	
func run_async(command):
	_t = Thread.new()
	_t.start(self, "run_async_thread", command)

func run_async_thread(command):
	var port = 1000 + (randi() % 1000)
	var s = TCP_Server.new()
	s.listen(port)
	OS.execute("ncat", ["127.0.0.1", str(port), "-c", command], false, [], true)
	while not s.is_connection_available():
		pass
	var c = s.take_connection()
	print("ok")
	while c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var available = c.get_available_bytes()
		if available > 0:
			var data = c.get_utf8_string(available)
			emit_signal("output", data)
			print(data)
	c.disconnect_from_host()
	s.stop()

# Run a simple command with arguments, blocking, using OS.execute.
func _exec(command, args=[]):
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
