extends Node2D

var source: String
var target: String

var repository: Control

func _ready():
	pass

func _process(_delta):
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
			$Target.text = ""
		$Target.show()
		$Line.hide()
		$Tip.hide()
	
	$Line.points[1] = end - repository.objects[source].position
	# Move the tip away from the object a bit.
	$Line.points[1] -= $Line.points[1].normalized()*30
	$Tip.position = $Line.points[1]
	$Tip.rotation = PI+$Line.points[0].angle_to($Line.points[1])
