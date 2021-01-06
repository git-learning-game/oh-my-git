class_name FileBrowserItem 
extends Control

signal clicked(what)
signal deleted(what)

export var label: String setget _set_label
var type = "file"
var repository

onready var label_node = $VBoxContainer/Label

func _ready():
	_set_label(label)
	#$PopupMenu.add_item("Delete file", 0)
	var exists_in_wd = repository.shell.run("test -f '%s' && echo yes || echo no" % label) == "yes\n"
	var exists_in_index = repository.shell.run("git ls-files --error-unmatch '%s' &>/dev/null && echo yes || echo no" % label) == "yes\n"
	var exists_in_head = repository.shell.run("git cat-file -e HEAD:'%s' &>/dev/null && echo yes || echo no" % label) == "yes\n"
	
	var wd_hash = repository.shell.run("git hash-object '%s' 2>/dev/null || true" % label)
	var index_hash = repository.shell.run("git ls-files -s '%s' | cut -f2 -d' '" % label)
	var head_hash = repository.shell.run("git ls-tree HEAD '%s' | cut -f1 | cut -f3 -d' '" % label)
	
	var conflict = Array(index_hash.split("\n")).size() > 2
	
	var offset_index = 0
	var offset_wd = 0
	var offset = 10
	
	if exists_in_index and exists_in_head and index_hash != head_hash:
		offset_index += 1
	
	if exists_in_wd and exists_in_head and wd_hash != head_hash:
		offset_wd += 1
	
	if exists_in_wd and exists_in_index and wd_hash != index_hash and offset_index == offset_wd:
		offset_wd += 1
		
	$VBoxContainer/Control/Index.rect_position.x += offset_index*offset
	$VBoxContainer/Control/Index.rect_position.y -= offset_index*offset
	
	$VBoxContainer/Control/WD.rect_position.x += offset_wd*offset
	$VBoxContainer/Control/WD.rect_position.y -= offset_wd*offset
	
	if conflict:
		$VBoxContainer/Control/Index.self_modulate = Color(1, 0.2, 0.2, 0.5)
	
	$VBoxContainer/Control/HEAD.visible = exists_in_head
	$VBoxContainer/Control/Index.visible = exists_in_index
	$VBoxContainer/Control/WD.visible = exists_in_wd

func _set_label(new_label):
	label = new_label
	if label_node:
		label_node.text = helpers.abbreviate(new_label, 30)

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		emit_signal("clicked", self)
#	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT and status != IconStatus.REMOVED:
#		$PopupMenu.set_position(get_global_mouse_position())
#		$PopupMenu.popup()
		
#func _set_status(new_status):
#	if status_icon:
#		match new_status:
#			IconStatus.NEW:
#				status_icon.texture = preload("res://images/new.svg")
#				status_icon.modulate = Color("33BB33")
#			IconStatus.REMOVED:
#				status_icon.texture = preload("res://images/removed.svg")
#				status_icon.modulate = Color("D10F0F")
#			IconStatus.CONFLICT:
#				status_icon.texture = preload("res://images/conflict.svg")
#				status_icon.modulate = Color("DE5E09")
#			IconStatus.EDIT:
#				status_icon.texture = preload("res://images/modified.svg")
#				status_icon.modulate = Color("344DED")
#			IconStatus.UNTRACKED:
#				status_icon.texture = preload("res://images/untracked.svg")
#				status_icon.modulate = Color("9209B8")
#			IconStatus.NONE:
#				status_icon.texture = null
#
#	status = new_status
#


func _popup_menu_pressed(_id):
	emit_signal("deleted", self)
