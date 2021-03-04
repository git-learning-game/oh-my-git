extends Node
class_name BetterShell

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
	
	#hacky_command += "export PATH=\'"+game.tmp_prefix+":'\"$PATH\";"
	hacky_command += "cd '%s' || exit 1;" % _cwd
	hacky_command += command

	#print(hacky_command)

	var result
	var shell_command_internal = game.shell_test(hacky_command)

	shell_command.output = shell_command_internal.output
	shell_command.exit_code = shell_command_internal.exit_code
	shell_command.emit_signal("done")
	
func _shell_binary():
	if _os == "X11" or _os == "OSX":
		return "bash"
	elif _os == "Windows":
		return "dependencies\\windows\\git\\bin\\bash.exe"
	else:
		helpers.crash("Unsupported OS: %s" % _os)
