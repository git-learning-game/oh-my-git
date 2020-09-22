extends Node2D

var id setget id_set
var content setget content_set
var type setget type_set
var repository: Control

var children = {} setget children_set
var id_always_visible = false
var held = false
var hovered = false

var arrow = preload("res://arrow.tscn")


func _ready():
	pass

func _process(_delta):
	if held:
		if not Input.is_action_pressed("click"):
			held = false
		else:
			global_position = get_global_mouse_position()

	if visible:
		apply_forces()

func apply_forces():
	var offset = Vector2(0, 80)
	
	for c in children.keys():
		if repository.objects.has(c):
			var other = repository.objects[c]
			if other.visible:
				var d = other.position.distance_to(position+offset)
				var dir = (other.position - (position+offset)).normalized()
				var f = (d*0.03)
				position += dir*f
				other.position -= dir*f
	
func id_set(new_id):
	id = new_id
	$ID.text = id
	
func content_set(new_content):
	content = new_content
	$Content.text = content

func type_set(new_type):
	type = new_type
	if type != "ref":
		$ID.text = $ID.text.substr(0,8)
	#elif type == "ref":
		#$ID.text = $ID.text.replace("refs/", "")
	match new_type:
		"blob":
			$Sprite.texture = preload("res://nodes/blob.svg")
			#$Rect.color = Color("#333333")
		"tree":
			$Sprite.texture = preload("res://nodes/tree.svg")
			#$Rect.color = Color.darkgreen
		"commit":
			$Sprite.texture = preload("res://nodes/commit.svg")
			#$Rect.color = Color.orange
		"tag":
			$Sprite.texture = preload("res://nodes/blob.svg")
			#$Rect.color = Color.blue
		"ref":
			$Sprite.texture = preload("res://nodes/ref.svg")
			#$Rect.color = Color("#6680ff")
			id_always_visible = true
		"head":
			$Sprite.texture = preload("res://nodes/ref.svg")
			#$Rect.color = Color.red
			id_always_visible = true
	if id_always_visible:
		$ID.show()

func children_set(new_children):
	for c in $Arrows.get_children():
		if not new_children.has(c.target):
			c.queue_free()
	for c in new_children:
		if not children.has(c):
			var a = arrow.instance()
			a.label = new_children[c]
			a.source = id
			a.target = c
			a.repository = repository
			$Arrows.add_child(a)  
	children = new_children

func _on_hover():
	hovered = true
	if not id_always_visible:
		$Content.visible = true
		$ID.visible = true
	
func _on_unhover():
	hovered = false
	if not id_always_visible:
		$Content.visible = false
		$ID.visible = false

func _input(event):
	if hovered:
		if event.is_action_pressed("click"):
			held = true
		elif event.is_action_pressed("right_click"):
			var input = get_tree().get_current_scene().find_node("Terminal").find_node("Control").find_node("Input")
			input.text += id
			input.caret_position = input.text.length()
	if event.is_action_released("click"):
		held = false
