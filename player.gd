extends KinematicBody2D

export var speed = 800

func _ready():
	pass

func _process(delta):
	var right = Input.get_action_strength("right") - Input.get_action_strength("left")
	var down = Input.get_action_strength("down") - Input.get_action_strength("up")
	move_and_slide(Vector2(right, down).normalized()*speed)
