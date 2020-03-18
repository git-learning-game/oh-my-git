extends Node2D

var label = "label" setget label_set
var target = Vector2(0,0) setget target_set

func _ready():
    pass

func _process(delta):
    var t = get_node("../..").objects[target]
    $Line.points[1] = t.position - global_position
    $Label.position = ($Line.points[0] + $Line.points[1])/2
    
func label_set(new_label):
    label = new_label
    $Label/ID.text = label

func target_set(new_target):
    target = new_target
