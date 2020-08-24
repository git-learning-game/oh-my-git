extends Node2D

var id setget id_set
var content setget content_set
var type setget type_set

var children = {} setget children_set

var arrow = preload("res://arrow.tscn")

func _ready():
	pass

func _process(delta):
	for c in children.keys():
		var other = get_node("..").objects[c]
		var d = other.position.distance_to(position)
		var dir = (other.position - position).normalized()
		var f = (d*0.05)
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
	match new_type:
		"blob":
			$Rect.color = Color.gray
		"tree":
			$Rect.color = Color.darkgreen
		"commit":
			$Rect.color = Color.orange
		"tag":
			$Rect.color = Color.blue
		"ref":
			$Rect.color = Color("#6680ff")
		"head":
			$Rect.color = Color.red

func children_set(new_children):
	for c in $Arrows.get_children():
		if not new_children.has(c.target):
			c.queue_free()
	for c in new_children:
		if not children.has(c):
			var a = arrow.instance()
			a.label = new_children[c]
			a.target = c
			$Arrows.add_child(a)  
	children = new_children

func _on_hover():
	$Content.visible = true
	
func _on_unhover():
	$Content.visible = false
  
