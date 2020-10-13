extends Node2D

var cards = [
	{"command": 'git add .', "arg_number": 0},
	{"command": 'git checkout', "arg_number": 1},
	{"command": 'touch "file$RANDOM"', "arg_number": 0},
	{"command": 'git commit --allow-empty -m "$RANDOM"', "arg_number": 0},
	{"command": 'git checkout -b "$RANDOM"', "arg_number": 0},
	{"command": 'git merge', "arg_number": 1}
]

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
	
	var pos_x = 100
	for card in cards:
		var new_card = preload("res://card.tscn").instance()
		new_card.command = card.command
		new_card.arg_number = card.arg_number
		new_card.position = Vector2(pos_x, get_viewport().size.y*3/4)
		pos_x += 250
		add_child(new_card)

func _update_repo():
	$Repository.update_everything()
