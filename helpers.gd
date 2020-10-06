extends Node

var debug_file_io = false

# Crash the game and display the error message.
func crash(message):
	push_error(message)
	print("FATAL ERROR: " + message)
	get_tree().quit()
	# Oh, still here? Let's crash more violently, by calling a non-existing method.
	# Violent delights have violent ends.
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
	
func careful_delete(path_inside):
	var expected_prefix
	
	var os = OS.get_name()
	
	if os == "X11":
		expected_prefix = "/home/%s/.local/share/git-hydra/tmp/" % OS.get_environment("USER")
	elif os == "OSX":
		expected_prefix = "/Users/%s/Library/Application Support/git-hydra/tmp/" % OS.get_environment("USER")
	elif os == "Windows":
		helpers.crash("Need to figure out delete_prefix on Windows")
	else:
		helpers.crash("Unsupported OS: %s" % os)
	
	if path_inside.substr(0,expected_prefix.length()) != expected_prefix:
		helpers.crash("Refusing to delete directory %s that does not start with %s" % [path_inside, expected_prefix])
	else:
		game.global_shell.cd(game.tmp_prefix_inside)
		game.global_shell.run("rm -rf '%s'" % path_inside)

func parse(file):
	var text = read_file(file)
	var result = {}
	var current_section
	
	var section_regex = RegEx.new()
	section_regex.compile("^\\[(.*)\\]$")
	
	var assignment_regex = RegEx.new()
	assignment_regex.compile("^([a-z ]+)=(.*)$")
	
	for line in text.split("\n"):
		# Skip comments.
		if line.substr(0, 1) == ";":
			continue
		
		# Parse a [section name].
		var m = section_regex.search(line)
		if m:
			current_section = m.get_string(1)
			result[current_section] = ""
			continue
		
		# Parse a direct=assignment.
		m = assignment_regex.search(line)
		if m:
			var key = m.get_string(1).strip_edges()
			var value = m.get_string(2).strip_edges()
			result[key] = value
			continue
			
		# At this point, the line is just content belonging to the current section.
		if current_section:
			result[current_section] += line + "\n"
	
	for key in result:
		result[key] = result[key].strip_edges()
	
	return result
