extends Control

func _ready():
	$HSplitContainer/Repository.path = "/tmp/active"

	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1920, 1080), 1.5)
