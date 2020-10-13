extends Node2D

var hovered = false
var dragged = false
var drag_offset

export var arg_number = 0
export var command = "" setget set_command
export var description = "" setget set_description

var _first_argument = null
var _home_position = null

func _ready():
	set_process_unhandled_input(true)
	position = get_viewport_rect().size
	
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
		elif event.button_index == BUTTON_LEFT and !event.pressed and dragged:
			dragged = false
			game.dragged_object = null
			modulate.a = 1
			
			
			if get_viewport().get_mouse_position().y < get_viewport().size.y/2:
				if arg_number == 0 :
					$"../Terminal".send_command($Label.text)
					buuurn()
				else:
					move_back()
			else:
				move_back()

func _mouse_entered():
	hovered = true

func _mouse_exited():
	hovered = false
	
func set_command(new_command):
	command = new_command
	$Label.text = command

func set_description(new_description):
	description = new_description
	$Description.text = description
	
func move_back():
	position = _home_position
	
func buuurn():
	queue_free()
	#$"..".draw_rand_card()
	$"..".arrange_cards()

func dropped_on(other):
	var full_command = ""
	match arg_number:
		1:	
			var argument = other.id
			if ($Label.text.begins_with("git checkout") or $Label.text.begins_with("git rebase")) and other.id.begins_with("refs/heads"):
				argument = Array(other.id.split("/")).pop_back()
			full_command = $Label.text + " " + argument
			$"../Terminal".send_command(full_command)
			buuurn()
		2:
			if _first_argument:
				full_command = $Label.text + " " + _first_argument + " " + other.id
				$"../Terminal".send_command(full_command)
				buuurn()
			else:
				_first_argument = other.id
				
				
				
		
			
	
