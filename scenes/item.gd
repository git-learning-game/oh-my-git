class_name Item
extends Node2D

enum IconStatus {NONE, NEW, REMOVED, CONFLICT, EDIT, UNTRACKED}
export(IconStatus) var status setget _set_status
export var label: String setget _set_label
var type = "file"
export var editable = true
var content setget _set_content
var held
var GRID_SIZE = 60
var file_browser

onready var label_node = $Label
onready var status_icon = $Status

func _ready():
	_set_label(label)
	_set_status(status)
	if not editable:
		type = "nothing"
	#$PopupMenu.add_item("Delete file", 0)

func _set_label(new_label):
	label = new_label
	if label_node:
		label_node.text = helpers.abbreviate(new_label, 30)

#func _gui_input(event):
#	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
#		emit_signal("clicked", self)
#	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT and status != IconStatus.REMOVED:
#		$PopupMenu.set_position(get_global_mouse_position())
#		$PopupMenu.popup()
		
func _set_status(new_status):
	if status_icon:
		match new_status:
			IconStatus.NEW:
				status_icon.texture = preload("res://images/new.svg")
				status_icon.modulate = Color("33BB33")
			IconStatus.REMOVED:
				status_icon.texture = preload("res://images/removed.svg")
				status_icon.modulate = Color("D10F0F")
			IconStatus.CONFLICT:
				status_icon.texture = preload("res://images/conflict.svg")
				status_icon.modulate = Color("DE5E09")
			IconStatus.EDIT:
				status_icon.texture = preload("res://images/modified.svg")
				status_icon.modulate = Color("344DED")
			IconStatus.UNTRACKED:
				status_icon.texture = preload("res://images/untracked.svg")
				status_icon.modulate = Color("9209B8")
			IconStatus.NONE:
				status_icon.texture = null
				
	status = new_status
	
func _set_content(new_content):
	content = new_content
	var attributes = helpers.parse(content)
	if attributes.has("x") and attributes.has("y"):
		position.x = int(attributes["x"]) * GRID_SIZE
		position.y = int(attributes["y"]) * GRID_SIZE
		
func move(direction):
	position += direction * GRID_SIZE
	if label != "":
		file_browser.shell.run("echo \"x = "+ String(position.x / GRID_SIZE) +"\ny = "+ String(position.y / GRID_SIZE) +"\" > " + label)
	if held:
		held.move(direction)
		
