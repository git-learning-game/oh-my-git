extends Node
class_name Shell

var _cwd

#signal output(text)

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
	env["GIT_AUTHOR_NAME"] = "You"
	env["GIT_COMMITTER_NAME"] = "You"
	env["GIT_AUTHOR_EMAIL"] = "you@example.com"
	env["GIT_COMMITTER_EMAIL"] = "you@example.com"
	
	var hacky_command = ""
	for variable in env:
		hacky_command += "export %s='%s';" % [variable, env[variable]]
	hacky_command += "cd '%s';" % _cwd
	hacky_command += command
	
	# Godot's OS.execute wraps each argument in double quotes before executing.
	# Because we want to be in a single-quote context, where nothing is evaluated,
	# we end those double quotes and start a single quoted string. For each single
	# quote appearing in our string, we close the single quoted string, and add
	# a double quoted string containing the single quote. Ooooof!
	#
	# Example: The string
	# 
	#     test 'fu' "bla" blubb
	# 
	# becomes
	# 
	#     "'test '"'"'fu'"'"' "bla" blubb
	# 
	hacky_command = '"\''+hacky_command.replace("'", "'\"'\"'")+'\'"'
	
	var output = game.exec(_shell_binary(), ["-c",  hacky_command])
	
	if debug:
		print(output)
	
	return output
	
func _shell_binary():
	var os = OS.get_name()
	
	if os == "X11":
		return "bash"
	elif os == "Windows":
		return "dependencies\\windows\\git\\bin\\bash.exe"
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
	var _pid = OS.execute("ncat", ["127.0.0.1", str(port), "-c", command], false, [], true)
	while not s.is_connection_available():
		pass
	var c = s.take_connection()
	while c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		read_from(c)
		OS.delay_msec(1000/30)
	read_from(c)
	c.disconnect_from_host()
	s.stop()

func read_from(c):
	var total_available = c.get_available_bytes()
	print(str(total_available)+" bytes available")
	while total_available > 0:
		var available = min(1024, total_available)
		total_available -= available
		print("reading "+str(available))
		var data = c.get_utf8_string(available)
		#emit_signal("output", data)
		print(data.size())
