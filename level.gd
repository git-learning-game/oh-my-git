extends Node
class_name Level

var slug
var description
var congrats
var start_commands
var goal_commands
var win_commands

# The path is an outer path.
func load(path):
	var parts = path.split("/")
	slug = parts[parts.size()-1]
	
	description = helpers.read_file(path+"/description", "(no description)")
	# Surround all lines indented with four spaces with [code] tags.
	var monospace_regex = RegEx.new()
	monospace_regex.compile("\n    (.*)\n")
	description = monospace_regex.sub(description, "\n      [code]$1[/code]\n", true)
	
	congrats = helpers.read_file(path+"/congrats", "Good job, you solved the level!\n\nFeel free to try a few more things or click 'Next Level'.")
	start_commands = helpers.read_file(path+"/start", "")
	goal_commands = helpers.read_file(path+"/goal", "")
	win_commands = helpers.read_file(path+"/win", "exit 1\n")
