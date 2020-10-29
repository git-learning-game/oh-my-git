extends Control

enum FileBrowserMode {
	WORKING_DIRECTORY,
	COMMIT,
	INDEX
}

export(String) var title setget _set_title
export(FileBrowserMode) var mode = FileBrowserMode.WORKING_DIRECTORY setget _set_mode

var shell
var commit setget _set_commit
var repository

var open_file

onready var grid = $Panel/Margin/Rows/Scroll/Grid
onready var text_edit = $Panel/TextEdit
onready var save_button = $Panel/TextEdit/SaveButton
onready var title_label = $Panel/Margin/Rows/Title

func _ready():
	update()
	_set_mode(mode)
	_set_title(title)

func _input(event):
	if event.is_action_pressed("save"):
		if text_edit.visible:
			save()
	
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
						var item = preload("res://scenes/file_browser_item.tscn").instance()
						item.label = file_path
						item.connect("clicked", self, "item_clicked")
						grid.add_child(item)
			FileBrowserMode.COMMIT:
				if commit:
					var files = Array(commit.repository.shell.run("git ls-tree --name-only -r %s" % commit.id).split("\n"))
					# The last entry is an empty string, remove it.
					files.pop_back()
					for file_path in files:
						var item = preload("res://scenes/file_browser_item.tscn").instance()
						item.label = file_path
						item.connect("clicked", self, "item_clicked")
						grid.add_child(item)
			FileBrowserMode.INDEX:
				if repository:
					var files = Array(repository.shell.run("git ls-files -s | cut -f2").split("\n"))
					# The last entry is an empty string, remove it.
					files.pop_back()
					for file_path in files:
						var item = preload("res://scenes/file_browser_item.tscn").instance()
						item.label = file_path
						item.connect("clicked", self, "item_clicked")
						grid.add_child(item)

func item_clicked(item):
	open_file = item.label
	match mode:
		FileBrowserMode.WORKING_DIRECTORY:
			text_edit.text = helpers.read_file(shell._cwd + item.label)
		FileBrowserMode.COMMIT:
			text_edit.text = commit.repository.shell.run("git show %s:\"%s\"" % [commit.id, item.label])
		FileBrowserMode.INDEX:
			text_edit.text = repository.shell.run("git show :\"%s\"" % [item.label])
	text_edit.show()
	text_edit.grab_focus()

func close():
	text_edit.hide()
	
func save():
	match mode:
		FileBrowserMode.WORKING_DIRECTORY:
			var fixme_path = shell._cwd
	
			# Add a newline to the end of the file if there is none.
			if text_edit.text.length() > 0 and text_edit.text.substr(text_edit.text.length()-1, 1) != "\n":
				text_edit.text += "\n"
			
			helpers.write_file(fixme_path+open_file, text_edit.text)
	close()

func _set_commit(new_commit):
	commit = new_commit
	update()
	
func _set_mode(new_mode):
	mode = new_mode
	
	if save_button:
		save_button.visible = mode == FileBrowserMode.WORKING_DIRECTORY
		text_edit.readonly = not mode == FileBrowserMode.WORKING_DIRECTORY
		text_edit.selecting_enabled = mode == FileBrowserMode.WORKING_DIRECTORY
		if mode == FileBrowserMode.WORKING_DIRECTORY:
			text_edit.focus_mode = Control.FOCUS_CLICK
		else:
			text_edit.focus_mode = Control.FOCUS_NONE

func _set_title(new_title):
	title = new_title
	if title_label:
		title_label.text = new_title

func very_best_sort(a,b):
	# We're looking at the third character because all entries have the form
	# "./.git/bla".
	if a.substr(2, 1) == "." and b.substr(2, 1) != ".":
		return false
	if a.substr(2, 1) != "." and b.substr(2, 1) == ".":
		return true
	return a.casecmp_to(b) == -1
