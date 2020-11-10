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
	$PopupMenu.add_item("New file", 1)

func _input(event):
	if event.is_action_pressed("save"):
		if text_edit.visible:
			save()
	
func clear():
	for item in grid.get_children():
		item.queue_free()
		
func substr2(s):
	return s.substr(2)
		
func update():
	if grid:
		clear()
		match mode:
			FileBrowserMode.WORKING_DIRECTORY:
				if shell:
					var wd_files = Array(shell.run("find . -type f").split("\n"))
					# The last entry is an empty string, remove it.
					wd_files.pop_back()
					wd_files = helpers.map(wd_files, self, "substr2")
					
					var deleted_files = []
					if shell.run("test -d .git && echo yes || echo no") == "yes\n":
						deleted_files = Array(shell.run("git status -s | grep '^.D' | sed -r 's/^...//'").split("\n"))
						deleted_files.pop_back()
						
					var files = wd_files + deleted_files
					
					files.sort_custom(self, "very_best_sort")
					#var is_visible = false
					for file_path in files:
						if file_path.substr(0, 5) == ".git/":
							continue
						#is_visible = true
						var item = preload("res://scenes/file_browser_item.tscn").instance()
						item.label = file_path
						item.connect("clicked", self, "item_clicked")
						item.connect("deleted", self, "item_deleted")
						item.status = get_file_status(file_path, shell, 1)
							
						grid.add_child(item)
					#visible = is_visible				
					
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
				#var is_visible = false					
				if repository and repository.there_is_a_git():
					var index_files = Array(repository.shell.run("git ls-files -s | cut -f2 | uniq").split("\n"))
					var deleted_files = Array(repository.shell.run("git status -s | grep '^D' | sed -r 's/^...//'").split("\n"))
					# The last entries are empty strings, remove them.
					index_files.pop_back()
					deleted_files.pop_back()
					var files = index_files + deleted_files
					for file_path in files:
						var item = preload("res://scenes/file_browser_item.tscn").instance()
						item.label = file_path
						item.connect("clicked", self, "item_clicked")
						item.status = get_file_status(file_path, repository.shell, 0)
						grid.add_child(item)
						#if item.status != item.IconStatus.NONE:
						#	is_visible = true		
				#visible = is_visible				
						
func get_file_status(file_path, shell, idx):
	var file_status = shell.run("git status -s '%s'" % file_path)
	if file_status.length()>0:
		match file_status[idx]:
			"D":
				return FileBrowserItem.IconStatus.REMOVED
			"M":
				return FileBrowserItem.IconStatus.EDIT
			"U":
				return FileBrowserItem.IconStatus.CONFLICT
			" ":
				return FileBrowserItem.IconStatus.NONE
			"A":
				return FileBrowserItem.IconStatus.NEW
			"?":
				return FileBrowserItem.IconStatus.UNTRACKED
	else:
		return FileBrowserItem.IconStatus.NONE

func item_clicked(item):
	if item.status == item.IconStatus.REMOVED:
		return
		
	match mode:
		FileBrowserMode.WORKING_DIRECTORY:
			text_edit.text = helpers.read_file(shell._cwd + item.label)
		FileBrowserMode.COMMIT:
			text_edit.text = commit.repository.shell.run("git show %s:\"%s\"" % [commit.id, item.label])
		FileBrowserMode.INDEX:
			if item.status == item.IconStatus.CONFLICT:
				return
			text_edit.text = repository.shell.run("git show :\"%s\"" % [item.label])
			
	open_file = item.label
	text_edit.show()
	text_edit.grab_focus()
	
func item_deleted(item):
	helpers.careful_delete(shell._cwd + item.label)
	update()

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
	update()
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
		
func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		$PopupMenu.set_position(get_global_mouse_position())
		$PopupMenu.popup()

func very_best_sort(a,b):
	if a[0] == "." and b[0] != ".":
		return false
	if a[0] != "." and b[0] == ".":
		return true
	return a.casecmp_to(b) == -1
