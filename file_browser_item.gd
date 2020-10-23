extends Control

signal clicked(what)

export var label: String setget _set_label

onready var label_node = $VBoxContainer/Label

func _ready():
	_set_label(label)

func _set_label(new_label):
	label = new_label
	if label_node:
		label_node.text = helpers.abbreviate(new_label, 30)

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		emit_signal("clicked", self)
