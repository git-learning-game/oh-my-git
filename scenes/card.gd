extends Node2D

var hovered = false
var dragged = false
var drag_offset

export var arg_number = 0
export var id = "" setget set_id
export var command = "" setget set_command
export var description = "" setget set_description
export var energy = 0 setget set_energy

var _first_argument = null
var _home_position = null
var _home_rotation = null

onready var energy_label = $Sprite/Energy

func _ready():
	set_process_unhandled_input(true)
	set_energy(energy)
	
func _process(delta):
	if game.energy >= energy:
		energy_label.modulate = Color(0.5, 1, 0.5)
	else:
		energy_label.modulate = Color(1, 1, 1)
		modulate = Color(1, 0.5, 0.5)
	
	if dragged:
		var mousepos = get_viewport().get_mouse_position()
		global_position = mousepos - drag_offset
	
	var target_scale = 1
	
	if hovered and not dragged:
		target_scale = 1.5
	
	scale = lerp(scale, Vector2(target_scale, target_scale), 10*delta)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed and hovered:
			dragged = true
			game.dragged_object = self
			$PickupSound.play()
			drag_offset = get_viewport().get_mouse_position() - global_position
			get_tree().set_input_as_handled()
			modulate.a = 0.5
		elif event.button_index == BUTTON_LEFT and !event.pressed and dragged:
			dragged = false
			game.dragged_object = null
			modulate.a = 1
			
			if get_viewport().get_mouse_position().y < get_viewport().size.y/3*2:
				if arg_number == 0 :
					try_play($Label.text)
				else:
					move_back()
			else:
				move_back()

func _mouse_entered():
	hovered = true
	z_index = 1

func _mouse_exited():
	hovered = false
	z_index = 0
	
func set_command(new_command):
	command = new_command
	$Label.text = command

func set_description(new_description):
	description = new_description
	$Description.text = description
	
func set_energy(new_energy):
	energy = new_energy
	if energy_label:
		energy_label.text = str(energy)

func set_id(new_id):
	id = new_id
	var texture = load("res://cards/%s.svg" % new_id)
	if texture:
		$Image.texture = texture
	
func move_back():
	position = _home_position
	rotation_degrees = _home_rotation
	$ReturnSound.play()
	
func buuurn():
	move_back()

func dropped_on(other):
	var full_command = ""
	match arg_number:
		1:	
			var argument = other.id
			if ($Label.text.begins_with("git checkout") or $Label.text.begins_with("git rebase")) and other.id.begins_with("refs/heads"):
				argument = Array(other.id.split("/")).pop_back()
			full_command = $Label.text + " " + argument
			try_play(full_command)
#		2:
#			if _first_argument:
#				full_command = $Label.text + " " + _first_argument + " " + other.id
#				$"../Terminal".send_command(full_command)
#				buuurn()
#			else:
#				_first_argument = other.id

func try_play(full_command):
	if game.energy >= energy:
		$PlaySound.play()
		var particles = preload("res://scenes/card_particles.tscn").instance()
		particles.position = position
		get_parent().add_child(particles)
		$"../../..".terminal.send_command(full_command)
		buuurn()
		game.energy -= energy
	else:
		move_back()
