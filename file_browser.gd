extends Control

var shell
var thread

func _ready():
	pass

func update():
	$FileTree.clear()
	var root_item = $FileTree.create_item()
	root_item.set_text(0, "FILES")
	
	var file_string = shell.run("find . -type f")
	var files = file_string.split("\n")
	files = Array(files)
	# The last entry is an empty string, remove it.
	files.pop_back()
	files.sort_custom(self, "very_best_sort")
	for file_path in files:
		file_path = file_path.substr(2)
		var child = $FileTree.create_item(root_item)
		child.set_text(0, file_path)
		#child.set_editable(0, true)


func _on_item_selected():
	var item = $FileTree.get_selected()
	var file_path = item.get_text(0)
	
	shell.run("'%s'/fake-editor-noblock '%s'" % [game.tmp_prefix_inside, file_path])
	
func very_best_sort(a,b):
	# We're looking at the third character because all entries have the form
	# "./.git/bla".
	if a.substr(2, 1) == "." and b.substr(2, 1) != ".":
		return false
	if a.substr(2, 1) != "." and b.substr(2, 1) == ".":
		return true
	return a.casecmp_to(b) == -1
