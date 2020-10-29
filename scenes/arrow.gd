extends Node2D

var source: String
var target: String setget set_target
var color = Color("333333") setget set_color

var repository: Control

func _ready():
	set_color(color)

func _process(_delta):
	position = Vector2(0,0)
	
	if not (repository and repository.objects.has(source)):
		return
	
	var start = repository.objects[source].position
	var end = start
	
	var parent_position = get_parent().get_parent().position
	
	var show_arrow = repository.objects.has(target) and repository.objects[target].visible and repository.objects[source].visible and repository.objects[source].type != "head"

	if show_arrow:
		end = repository.objects[target].position
		$Target.hide()
		
	$Line.visible = show_arrow
	$Tip.visible = show_arrow
	
	if $Target.text.substr(0, 5) != "refs/" or repository.objects.has(target):
		$Target.text = ""

	$Line.points[0] = start - parent_position
	$Line.points[1] = end - parent_position

	#$Line.points[0] += ($Line.points[1] - $Line.points[0]).normalized()*30
	$Line.points[1] -= ($Line.points[1] - $Line.points[0]).normalized()*30
	$Tip.position = $Line.points[1]
	$Tip.rotation = PI + atan2($Line.points[0].y - $Line.points[1].y, $Line.points[0].x - $Line.points[1].x)

func set_color(new_color):
	color = new_color
	$Line.default_color = new_color
	$Tip/Polygon.color = new_color

func set_target(new_target):
	target = new_target
	$Target.text = new_target
