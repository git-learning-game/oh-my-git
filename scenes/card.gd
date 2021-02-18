extends Node2D

var hovered = false
var dragged = false
var drag_offset

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
			_turn_on_highlights()
			$PickupSound.play()
			drag_offset = get_viewport().get_mouse_position() - global_position
			get_tree().set_input_as_handled()
			modulate.a = 0.5
		elif event.button_index == BUTTON_LEFT and !event.pressed and dragged:
			dragged = false
			game.dragged_object = null
			_turn_off_highlights()
			modulate.a = 1
			
			if "[string]" in command:
				var dialog = preload("res://scenes/input_dialog.tscn").instance()
				add_child(dialog)
				dialog.popup_centered()
				dialog.connect("entered", self, "entered_string")
				dialog.connect("popup_hide", self, "move_back")
				hide()
			elif "[" in command:
				move_back()
			else:
				try_play(command)
				
func _turn_on_highlights():
	var arg_regex = RegEx.new()
	arg_regex.compile("\\[(.*)\\]")
	var m = arg_regex.search(command)
	if m:
		var types = Array(m.get_string(1).split(","))
		for type in types:
			for area in get_tree().get_nodes_in_group("drop_areas"):
				area.highlight(type.strip_edges())
		
func _turn_off_highlights():
	for area in get_tree().get_nodes_in_group("drop_areas"):
		area.highlighted = false
				
func _mouse_entered():
	hovered = true
	z_index = 1

func _mouse_exited():
	hovered = false
	z_index = 0
	
func set_command(new_command):
	command = new_command
	var commands = new_command.split("[", true, 1)
	var args = ''
	if commands.size() > 1:
		args = commands[1].replace("]", "")
		args = args.replace(", ", "/")
		args = args.replace("ref", " [img=20]images/ref.svg[/img] ")
		args = args.replace("commit", " [img=20]images/commit.svg[/img] ")
		args = args.replace("string", " [img=20]images/string.svg[/img] ")
		args = args.replace("head", " [img=20]images/head.svg[/img] ")
		args = args.replace("file", " [img=20]images/file.svg[/img] ")
		args = args.replace("remote", " [img=20]images/remote.svg[/img] ")
	$Label.bbcode_text = commands[0] + args
	#$Label.text = command

func set_description(new_description):
	description = new_description
	$Description.text = description
	
func set_energy(new_energy):
	energy = new_energy
	if energy_label:
		energy_label.text = str(energy)

func set_id(new_id):
	id = new_id
	var art_path = "res://cards/%s.svg" % new_id
	var file = File.new()
	#if file.file_exists(art_path):
	var texture = load(art_path)
	if texture:
		$Image.texture = texture
	$Panel/Glow.visible = not id in game.state["played_cards"]
	
func move_back():
	position = _home_position
	rotation_degrees = _home_rotation
	$ReturnSound.play()
	show()

func dropped_on(other):
	if "[" in command:
		var argument
		if other.type == "file" or other.type == "remote":
			argument = other.label
		else:
			argument = other.id
			
		if (command.begins_with("git checkout") or command.begins_with("git rebase") or command.begins_with("git branch -D")) and argument.begins_with("refs/heads"):
			argument = Array(argument.split("/")).pop_back()
			
		var arg_regex = RegEx.new()
		arg_regex.compile("\\[(.*)\\]")
		var full_command = arg_regex.sub(command, argument)
		try_play(full_command)

func try_play(full_command):
	if game.energy >= energy:
		var terminal = $"../../../..".terminal
		terminal.send_command(full_command)
		#yield(terminal, "command_done")
		game.used_cards = true
		$PlaySound.play()
		var particles = preload("res://scenes/card_particles.tscn").instance()
		particles.position = position
		get_parent().add_child(particles)
		move_back()
		game.energy -= energy
		if not id in game.state["played_cards"]:
			game.state["played_cards"].push_back(id)
			game.save_state()
			$Panel/Glow.hide()
	else:
		move_back()

func entered_string(string):
	try_play(command.replace("[string]", "'"+string+"'"))
