extends Control

func _ready():
	var args = helpers.parse_args()
	var path = game.tmp_prefix_inside
	if args.has("sandbox"):
		if args["sandbox"] is String:
			var dir = Directory.new()
			if dir.dir_exists(args["sandbox"]):
				path = args["sandbox"]
			else:
				helpers.crash("Directory %s does not exist" % args["sandbox"])
	
	$HSplitContainer/Repository.path = path

	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1920, 1080), 1.5)
