extends Node2D

var hovered = false
var dragged = false
var drag_offset

func _ready():
	set_process_unhandled_input(true)
	
func _process(delta):
	if dragged:
		var mousepos = get_viewport().get_mouse_position()
		position = mousepos - drag_offset

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed and hovered:
			dragged = true
			game.dragged_object = self
			drag_offset = get_viewport().get_mouse_position() - global_position
			get_tree().set_input_as_handled()
			modulate.a = 0.5
		elif event.button_index == BUTTON_LEFT and !event.pressed:
			dragged = false
			game.dragged_object = null
			modulate.a = 1
			

func _mouse_entered():
	hovered = true

func _mouse_exited():
	hovered = false

func dropped_on(other):
	#print("I have been dropped on "+str(other.id))
	print("Running " + $Label.text + " " + other.id)
	var command = $Label.text + " " + other.id
	$"../Terminal".send_command(command)
	queue_free()
