extends Node
class_name Chapter

var slug
var levels

# Path is an outer path.
func load(path):
	levels = []
	
	var parts = path.split("/")
	slug = parts[parts.size()-1]
	
	var level_names = []
	var dir = Directory.new()
	dir.open("res://levels/%s" % slug)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file != "sequence":
			level_names.append(file)

	dir.list_dir_end()
	level_names.sort()
	
	var final_level_sequence = []
	
	var level_sequence = Array(helpers.read_file("res://levels/%s/sequence" % slug, "").split("\n"))
	
	for level in level_sequence:
		if level == "":
			continue
		if not level_names.has(level):
			helpers.crash("Level '%s' is specified in the sequence, but could not be found" % level)
		level_names.erase(level)
		final_level_sequence.push_back(level)
	
	#final_level_sequence += level_names
	
	for l in final_level_sequence:
		var level = Level.new()
		level.load("res://levels/%s/%s" % [slug, l])
		levels.push_back(level)

func _to_string():
	return str(levels)
