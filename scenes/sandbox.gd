extends Control

func _ready():
	var path = null
	
	var args = helpers.parse_args()
	if args.has("sandbox"):
		if args["sandbox"] is String:
			if args["sandbox"] == ".":
				args["sandbox"] = OS.get_environment("PWD")
		
			if DirAccess.open(args["sandbox"]):
				path = args["sandbox"]
			else:
				helpers.crash("DirAccess %s does not exist" % args["sandbox"])
	
	if path == null:
		path = game.tmp_prefix+"/repos/sandbox/"
		await helpers.careful_delete(path)
		
		await game.global_shell.run("mkdir '%s'" % path)
		await game.global_shell.cd(path)
		await game.global_shell.run("git init")
		await game.global_shell.run("git symbolic-ref HEAD refs/heads/main")
	
	$Columns/Repository.path = path

	#ToDo strech modes
	#get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1920, 1080), 1.5)

	$Columns/Terminal.repository = $Columns/Repository

func update_repo():
	$Columns/Repository.update_everything()
