extends Node2D

var id setget id_set
var content setget content_set
var type setget type_set
var repository: Node2D

var children = {} setget children_set
var id_always_visible = false

var arrow = preload("res://arrow.tscn")

func _ready():
	pass

func _process(delta):
	for c in children.keys():
		if get_node("..").objects.has(c):
			var other = get_node("..").objects[c]
			var d = other.position.distance_to(position)
			var dir = (other.position - position).normalized()
			var f = (d*0.01)
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
	elif type == "ref":
		var parts = $ID.text.split("/")
		$ID.text = parts[parts.size()-1]
	match new_type:
		"blob":
			$Rect.color = Color("#333333")
		"tree":
			$Rect.color = Color.darkgreen
		"commit":
			$Rect.color = Color.orange
		"tag":
			$Rect.color = Color.blue
			id_always_visible = true
		"ref":
			$Rect.color = Color("#6680ff")
			id_always_visible = true
		"head":
			$Rect.color = Color.red
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
			a.target = c
			a.repository = repository
			$Arrows.add_child(a)  
	children = new_children

func _on_hover():
	$Content.visible = true
	$ID.visible = true
	
func _on_unhover():
	if not id_always_visible:
		$Content.visible = false
		$ID.visible = false
  
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		var input = get_tree().get_current_scene().find_node("Terminal").find_node("Control").find_node("Input")
		input.text += $ID.text
		input.caret_position = input.text.length()
