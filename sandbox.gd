extends Control

func _ready():
	var pwd = "/tmp/active/" # OS.get_environment("PWD")
	$HSplitContainer/Repository.path = pwd

	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1920, 1080), 1.5)
