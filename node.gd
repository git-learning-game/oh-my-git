extends Node2D

var id setget id_set
var content setget content_set
var type setget type_set

var children = [] setget children_set

var arrow = preload("res://arrow.tscn")

func _ready():
    pass

func _process(delta):
    pass
    
func id_set(new_id):
    id = new_id
    $ID.text = id
    
func content_set(new_content):
    content = new_content
    $Content.text = content

func type_set(new_type):
    type = new_type
    $ID.text = new_type + " " + $ID.text.substr(0,8)
    match new_type:
        "blob":
            $Rect.color = Color.gray
        "tree":
            $Rect.color = Color.darkgreen
        "commit":
            $Rect.color = Color.orange
        "tag":
            $Rect.color = Color.blue

func children_set(new_children):
    children = new_children
    for c in children:
        var a = arrow.instance()
        a.label = "test"
        a.target = c
        add_child(a)

func _on_hover():
    $Content.visible = true
    
func _on_unhover():
    $Content.visible = false
  
