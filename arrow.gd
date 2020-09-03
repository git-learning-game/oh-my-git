extends Node2D

var label = "label" setget label_set
var target: String setget target_set
var repository: Container

func _ready():
	pass

func _process(delta):
	if repository and repository.objects.has(target):
		var t = repository.objects[target]
		#print(t)
		$Line.points[1] = t.global_position - global_position
		$Label.position = ($Line.points[0] + $Line.points[1])/2
		$Tip.position = ($Line.points[0] + $Line.points[1])/2
		$Tip.rotation = PI+$Line.points[0].angle_to($Line.points[1])
	
func label_set(new_label):
	label = new_label
	$Label/ID.text = label

func target_set(new_target):
	target = new_target
