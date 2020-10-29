extends Node2D

var id setget id_set
var content setget content_set
var type setget type_set
var repository: Control

onready var content_label = $Content/ContentLabel
onready var file_browser = $OnTop/FileBrowser

var children = {} setget children_set
var id_always_visible = false
var held = false
var hovered = false
var start_pos = null

var arrow = preload("res://scenes/arrow.tscn")

func _ready():
	content_set(content)
	type_set(type)
	if not repository.simplified_view:
		$Pop.pitch_scale = rand_range(0.8, 1.2)
		$Pop.play()

func _process(delta):
	if held:
		if not Input.is_action_pressed("click"):
			held = false
		else:
			global_position = get_global_mouse_position()

	if visible:
		if type == "head":
			for c in children:
				if repository.objects.has(c):
					var other = repository.objects[c]
					var offset = Vector2(0, -45)
					var target_position = other.position + offset
					position = lerp(position, target_position, 10*delta)
		else:
			apply_forces()

func apply_forces():
	var offset = Vector2(-80, 0)
	
	for c in children.keys():
#		if type == "ref" or type == "head":
#			offset = Vector2(0, 80)
		if repository.objects.has(c):
			var other = repository.objects[c]
			if other.visible:
				var d = other.position.distance_to(position+offset)
				var dir = (other.position - (position+offset)).normalized()
				var f = (d*0.06)
				position += dir*f
				other.position -= dir*f
	
func id_set(new_id):
	id = new_id
	$ID.text = id
	
func content_set(new_content):
	content = new_content
	if content_label:
		content_label.text = content

func type_set(new_type):
	type = new_type
	if type == "commit" and file_browser:
		file_browser.commit = self
		file_browser.title = "Commit"
	if type != "ref":
		$ID.text = $ID.text.substr(0,8)
	z_index = -1
	match new_type:
		"blob":
			$Sprite.texture = preload("res://nodes/blob.svg")
		"tree":
			$Sprite.texture = preload("res://nodes/tree.svg")
		"commit":
			$Sprite.texture = preload("res://nodes/commit.svg")
		"tag":
			$Sprite.texture = preload("res://nodes/blob.svg")
		"ref":
			$Sprite.texture = preload("res://nodes/ref.svg")
			id_always_visible = true
		"head":
			$Sprite.texture = preload("res://nodes/head.svg")
			id_always_visible = false
			z_index = 0
	if id_always_visible:
		$ID.show()

func children_set(new_children):
	for c in $Arrows.get_children():
		if not new_children.has(c.target):
			c.queue_free()
	for c in new_children:
		if not children.has(c):
			var a = arrow.instance()
			if type == "commit":
				#a = time_arrow.instance()
				a.source = c
				a.target = id
				a.color = Color("c2bf26")
			else:
				a.source = id
				a.target = c
			a.repository = repository
			$Arrows.add_child(a)  
	children = new_children

func _on_hover():
	hovered = true
	if not id_always_visible and type != "head":
		if not file_browser.visible:
			content_label.visible = true
		#$ID.visible = true
	
func _on_unhover():
	hovered = false
	if not id_always_visible and type != "head":
		content_label.visible = false
		#$ID.visible = false

func _input(event):
	if hovered:
		if event.is_action_pressed("click") and type != "head":
			start_pos = get_viewport().get_mouse_position()
			held = true
		elif event.is_action_pressed("right_click"):
			var input = get_tree().get_current_scene().find_node("Input")
			input.text += id
			input.caret_position = input.text.length()
	if event.is_action_released("click"):
		held = false
		if type == "commit":
			if start_pos:
				var dist = get_viewport().get_mouse_position() - start_pos
				if dist.length() < 3:
					var state = file_browser.visible
					repository.close_all_file_browsers()
					file_browser.visible = not state
					content_label.visible = state
		
		start_pos = null
