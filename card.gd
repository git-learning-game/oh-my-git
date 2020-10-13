extends Node2D

var dragged = false
var drag_offset

func _ready():
	set_process_unhandled_input(true)
	
func _process(delta):
	if dragged:
		var mousepos = get_viewport().get_mouse_position()
		position = mousepos - drag_offset

func _unhandled_input(event):
	print("input event!")
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			dragged = true
			drag_offset = get_viewport().get_mouse_position() - global_position
		elif event.button_index == BUTTON_LEFT and !event.pressed:
			dragged = false
