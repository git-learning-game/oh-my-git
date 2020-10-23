extends Control

var shell
var thread

onready var grid = $Panel/Margin/Rows/Scroll/Grid

func update():
	for item in grid.get_children():
		item.queue_free()
	
	var file_string = shell.run("find . -type f")
	var files = file_string.split("\n")
	files = Array(files)
	# The last entry is an empty string, remove it.
	files.pop_back()
	files.sort_custom(self, "very_best_sort")
	for file_path in files:
		file_path = file_path.substr(2)
		if file_path.substr(0, 5) == ".git/":
			continue
		var item = preload("res://file_browser_item.tscn").instance()
		item.label = file_path
		item.connect("clicked", self, "item_clicked")
		grid.add_child(item)
		#child.set_editable(0, true)

func item_clicked(item):
	var file_path = item.label
	shell.run("'%s'/fake-editor-noblock '%s'" % [game.tmp_prefix_inside, file_path])

func very_best_sort(a,b):
	# We're looking at the third character because all entries have the form
	# "./.git/bla".
	if a.substr(2, 1) == "." and b.substr(2, 1) != ".":
		return false
	if a.substr(2, 1) != "." and b.substr(2, 1) == ".":
		return true
	return a.casecmp_to(b) == -1
