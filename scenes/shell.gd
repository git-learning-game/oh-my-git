extends Node
class_name Shell

var exit_code

var _cwd
var _os = OS.get_name()

func _init():
	# Create required directories and move into the tmp directory.
	_cwd = "/tmp"
	run("mkdir -p '%s/repos'" % game.tmp_prefix)
	_cwd = game.tmp_prefix
	
func cd(dir):
	_cwd = dir

# Run a shell command given as a string. Run this if you're interested in the
# output of the command.
func run(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	shell_command.command = command
	shell_command.crash_on_fail = crash_on_fail
	
	run_async_thread(shell_command)
	exit_code = shell_command.exit_code
	return shell_command.output

func run_async(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	shell_command.command = command
	shell_command.crash_on_fail = crash_on_fail
	
	var t = Thread.new()
	shell_command.thread = t
	t.start(self, "run_async_thread", shell_command)
	
	return shell_command
	
func run_async_thread(shell_command):
	var debug = false
	
	var command = shell_command.command
	var crash_on_fail = shell_command.crash_on_fail
	
	if debug:
		print("$ %s" % command)
	
	var env = {}
	env["HOME"] = game.tmp_prefix
	
	var hacky_command = ""
	for variable in env:
		hacky_command += "export %s='%s';" % [variable, env[variable]]
	
	hacky_command += "export PATH=\'"+game.tmp_prefix+":'\"$PATH\";"
	hacky_command += "cd '%s' || exit 1;" % _cwd
	hacky_command += command

	var result
	if _os == "X11" or _os == "OSX":
		# Godot's OS.execute wraps each argument in double quotes before executing
		# on Linux and macOS.
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
		#     "'test '"'"'fu'"'"' "bla" blubb"
		
		hacky_command = '"\''+hacky_command.replace("'", "'\"'\"'")+'\'"'
		result = helpers.exec(_shell_binary(), ["-c",  hacky_command], crash_on_fail)
	elif _os == "Windows":
		# On Windows, if the command contains a newline (even if inside a string),
		# execution will end. To avoid that, we first write the command to a file,
		# and run that file with bash.
		var script_path = game.tmp_prefix + "command" + str(randi())
		helpers.write_file(script_path, hacky_command)
		result = helpers.exec(_shell_binary(), [script_path], crash_on_fail)
	else:
		helpers.crash("Unimplemented OS: %s" % _os)
	
	if debug:
		print(result["output"])
	
	shell_command.output = result["output"]
	shell_command.exit_code = result["exit_code"]
	shell_command.emit_signal("done")
	
func _shell_binary():
	if _os == "X11" or _os == "OSX":
		return "bash"
	elif _os == "Windows":
		return "dependencies\\windows\\git\\bin\\bash.exe"
	else:
		helpers.crash("Unsupported OS: %s" % _os)

#var _t	
#func run_async(command):
#	_t = Thread.new()
#	_t.start(self, "run_async_thread", command)
#
#func run_async_thread(command):
#	var port = 1000 + (randi() % 1000)
#	var s = TCP_Server.new()
#	s.listen(port)
#	var _pid = OS.execute("ncat", ["127.0.0.1", str(port), "-c", command], false, [], true)
#	while not s.is_connection_available():
#		pass
#	var c = s.take_connection()
#	while c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
#		read_from(c)
#		OS.delay_msec(1000/30)
#	read_from(c)
#	c.disconnect_from_host()
#	s.stop()

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
