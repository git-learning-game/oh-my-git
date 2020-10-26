extends Node2D

var hovered = false

func _ready():
	pass
	
func _mouse_entered():
	hovered = true

func _mouse_exited():
	hovered = false
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and !event.pressed and hovered:
			if game.dragged_object:
				game.dragged_object.dropped_on($"..")
