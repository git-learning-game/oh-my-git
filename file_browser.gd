extends Control

enum FileBrowserMode {
	WORKING_DIRECTORY,
	COMMIT,
	INDEX
}

export(FileBrowserMode) var mode = FileBrowserMode.WORKING_DIRECTORY

var shell
var commit setget _set_commit
var repository

onready var grid = $Panel/Margin/Rows/Scroll/Grid

func _ready():
	update()
	
func clear():
	for item in grid.get_children():
		item.queue_free()
		
func update():
	if grid:
		clear()
		match mode:
			FileBrowserMode.WORKING_DIRECTORY:
				if shell:
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
			FileBrowserMode.COMMIT:
				if commit:
					var files = Array(commit.repository.shell.run("git ls-tree --name-only -r %s" % commit.id).split("\n"))
					# The last entry is an empty string, remove it.
					files.pop_back()
					for file_path in files:
						var item = preload("res://file_browser_item.tscn").instance()
						item.label = file_path
						#item.connect("clicked", self, "item_clicked")
						grid.add_child(item)
			FileBrowserMode.INDEX:
				if repository:
					var files = Array(repository.shell.run("git ls-files -s | cut -f2").split("\n"))
					# The last entry is an empty string, remove it.
					files.pop_back()
					for file_path in files:
						var item = preload("res://file_browser_item.tscn").instance()
						item.label = file_path
						#item.connect("clicked", self, "item_clicked")
						grid.add_child(item)

func item_clicked(item):
	var file_path = item.label
	shell.run("'%s'/fake-editor-noblock '%s'" % [game.tmp_prefix_inside, file_path])

func _set_commit(new_commit):
	commit = new_commit
	update()

func very_best_sort(a,b):
	# We're looking at the third character because all entries have the form
	# "./.git/bla".
	if a.substr(2, 1) == "." and b.substr(2, 1) != ".":
		return false
	if a.substr(2, 1) != "." and b.substr(2, 1) == ".":
		return true
	return a.casecmp_to(b) == -1
