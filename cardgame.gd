extends Node2D

func _ready():
	
	var path = game.tmp_prefix_inside+"/repos/sandbox/"
	helpers.careful_delete(path)
	
	game.global_shell.run("mkdir " + path)
	game.global_shell.cd(path)
	game.global_shell.run("git init")
	game.global_shell.run("git symbolic-ref HEAD refs/heads/main")
	game.global_shell.run("git commit --allow-empty -m 'Initial commit'")
	
	$Repository.path = path

	$Terminal.repository = $Repository

func _update_repo():
	$Repository.update_everything()
