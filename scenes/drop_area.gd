extends Node2D

var hovered = false
var highlighted = false setget _set_highlighted

func _ready():
	pass
	
func _mouse_entered():
	hovered = true

func _mouse_exited():
	hovered = false
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and !event.pressed and hovered:
			if highlighted and game.dragged_object:
				game.dragged_object.dropped_on($"..")

func _set_highlighted(new_highlighted):
	highlighted = new_highlighted
	$Highlight.visible = highlighted

func highlight(type):
	if get_parent().type == type:
		_set_highlighted(true)
