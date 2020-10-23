extends Node2D

var label = "label" setget label_set

var source: String
var target: String

var repository: Control

func _ready():
	pass

func _process(_delta):
	#position = -repository.objects[source].position
	position = Vector2(0,0)
	
	if not (repository and repository.objects.has(source)):
		return
	
	var start = repository.objects[source].position
	var end = start + Vector2(0, 60)
	
	if repository and repository.objects.has(target) and repository.objects[target].visible:
		var t = repository.objects[target]
		end = t.position
		$Target.hide()
	else:
		$Target.text = target
		if $Target.text.substr(0, 5) != "refs/":
			$Target.text = ""#$Target.text.substr(0,8)
		$Target.show()
		$Line.hide()
		$Tip.hide()
	
	$Line.points[1] = end - repository.objects[source].position
	# Move the tip away from the object a bit.
	$Line.points[1] -= $Line.points[1].normalized()*30
	#$Label.position = ($Line.points[0] + $Line.points[1])/1.3
	$Tip.position = $Line.points[1]
	$Tip.rotation = PI+$Line.points[0].angle_to($Line.points[1])
	
func label_set(new_label):
	label = new_label
	$Label/ID.text = label
