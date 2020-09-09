extends Node
class_name Shell

var _cwd

signal output(text)

func _init():
	_cwd = "/tmp"
	
func cd(dir):
	_cwd = dir

# Run a shell command given as a string. Run this if you're interested in the
# output of the command.
func run(command):
	var debug = false
	
	if debug:
		print("$ %s" % command)
	
	var env = {}
	env["EDITOR"] = game.fake_editor
	
	var hacky_command = ""
	for variable in env:
		hacky_command += "export %s='%s';" % [variable, env[variable]]
	hacky_command += "cd '%s';" % _cwd
	hacky_command += command
	
	var output = game.exec(_shell_binary(), ["-c",  hacky_command])
	
	if debug:
		print(output)
	
	return output
	
func _shell_binary():
	var os = OS.get_name()
	
	if os == "X11":
		return "sh"
	elif os == "Windows":
		return "dependencies\\windows\\git\\bin\\sh.exe"
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

