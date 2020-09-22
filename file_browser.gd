extends Control

var shell
var thread

func _ready():
	pass

func update():
	$FileTree.clear()
	var root_item = $FileTree.create_item()
	root_item.set_text(0, "FILES")
	
	var file_string = shell.run("find -type f")
	var files = file_string.split("\n")
	files = Array(files)
	files.sort()
	for file_path in files:
		file_path = file_path.substr(2)
		var child = $FileTree.create_item(root_item)
		child.set_text(0, file_path)
		#child.set_editable(0, true)


func _on_item_selected():
	var item = $FileTree.get_selected()
	var file_path = item.get_text(0)

	shell.run("/tmp/fake-editor-noblock "+file_path)
	
