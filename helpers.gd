extends Node

var debug_file_io = false

# Crash the game and display the error message.
func crash(message):
	push_error(message)
	print("FATAL ERROR: " + message)
	get_tree().quit()
	# Oh, still here? Let's crash more violently, by calling a non-existing method.
	get_tree().fatal_error()

# Run a simple command with arguments, blocking, using OS.execute.
func exec(command, args=[], crash_on_fail=true):
	var debug = false
	
	if debug:
		print("exec: %s [%s]" % [command, PoolStringArray(args).join(", ")])
		
	var output = []
	var exit_code = OS.execute(command, args, true, output, true)
	output = output[0]
	
	if exit_code != 0 and crash_on_fail:
		helpers.crash("OS.execute failed: %s [%s] Output: %s" % [command, PoolStringArray(args).join(", "), output])
	
	if debug:
		print(output)

	return output

# Return the contents of a file. If no fallback_string is provided, crash when
# the file doesn't exist.
func read_file(path, fallback_string=null):
	if debug_file_io:
		print("reading " + path)
	var file = File.new()
	var open_status = file.open(path, File.READ)
	if open_status == OK:
		var content = file.get_as_text()
		file.close()
		return content
	else:
		if fallback_string != null:
			return fallback_string
		else:
			helpers.crash("File %s could not be read, and has no fallback" % path)

func write_file(path, content):
	if debug_file_io:
		print("writing " + path)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(content)
	file.close()
	return true

func parse_args():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.substr(0, 2) == "--":
			# Parse valid command-line arguments into a dictionary
			if argument.find("=") > -1:
				var key_value = argument.split("=")
				arguments[key_value[0].lstrip("--")] = key_value[1]
			else:
				arguments[argument.lstrip("--")] = true
	return arguments
