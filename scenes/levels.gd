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
		elif not file.begins_with(".") and file != "sequence":
			chapter_names.append(file)

	dir.list_dir_end()
	chapter_names.sort()
	
	var final_chapter_sequence = []
	
	var chapter_sequence = Array(helpers.read_file("res://levels/sequence", "").split("\n"))
	
	for chapter in chapter_sequence:
		if chapter == "":
			continue
		if not chapter_names.has(chapter):
			helpers.crash("Chapter '%s' is specified in the sequence, but could not be found" % chapter)
		chapter_names.erase(chapter)
		final_chapter_sequence.push_back(chapter)
	
	#final_chapter_sequence += chapter_names
	
	for c in final_chapter_sequence:
		var chapter = Chapter.new()
		chapter.load("res://levels/%s" % c)
		chapters.push_back(chapter)
