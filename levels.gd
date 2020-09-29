extends Node

var chapters

func _ready():
	reload()
	
func reload():
	chapters = []
	
	var dir = Directory.new()
	dir.open("res://levels")
	dir.list_dir_begin()

	var chapter_names = []
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			chapter_names.append(file)

	dir.list_dir_end()
	chapter_names.sort()
	
	for c in chapter_names:
		var chapter = Chapter.new()
		chapter.load("res://levels/%s" % c)
		chapters.push_back(chapter)
