extends Node2D

var label = "label" setget label_set
var target: String setget target_set
var repository: Container

func _ready():
	pass

func _process(_delta):
	var end = global_position + Vector2(0, 50)
	if repository and repository.objects.has(target) and repository.objects[target].visible:
		var t = repository.objects[target]
		end = t.global_position
		$Target.hide()
	else:
		$Target.text = target
		if $Target.text.substr(0, 5) != "refs/":
			$Target.text = ""#$Target.text.substr(0,8)
		$Target.show()
	$Line.points[1] = end - global_position
	$Label.position = ($Line.points[0] + $Line.points[1])/1.3
	$Tip.position = ($Line.points[0] + $Line.points[1])/1.3
	$Tip.rotation = PI+$Line.points[0].angle_to($Line.points[1])
	
func label_set(new_label):
	label = new_label
	$Label/ID.text = label

func target_set(new_target):
	target = new_target
