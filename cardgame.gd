extends Node2D

var cards = [
	{"command": 'git add .', "arg_number": 0, "description": "Add all files in the working directory to the index."},
	{"command": 'git checkout', "arg_number": 1, "description": "Point HEAD to a branch or commit, and update the index and the working directory."},
	{"command": 'touch "file$RANDOM"', "arg_number": 0, "description": "Create a new file."},
	{"command": 'git commit --allow-empty -m "$RANDOM"', "arg_number": 0, "description": "Add a new commit under HEAD."},
	{"command": 'git checkout -b "$RANDOM"', "arg_number": 0, "description": "Create a new branch and switch to it."},
	{"command": 'git merge', "arg_number": 1, "description": "Merge specified commit into HEAD."},
	{"command": 'git update-ref -d', "arg_number": 1, "description": "Delete a ref."},
	{"command": 'git reflog expire --expire=now --all; git prune', "arg_number": 0, "description": "Delete all unreferenced objects."},
	{"command": 'git rebase', "arg_number": 1, "description": "Rebase current branch on top of specified commit."},
	{"command": 'git push -f', "arg_number": 0, "description": "Push current branch to the remote. Will make everyone angry."},
]

func _ready():
#	var path = game.tmp_prefix_inside+"/repos/sandbox/"
#	helpers.careful_delete(path)
#
#	game.global_shell.run("mkdir " + path)
#	game.global_shell.cd(path)
#	game.global_shell.run("git init")
#	game.global_shell.run("git remote add origin ../remote")
#	$Repository.path = path
#	$Terminal.repository = $Repository
#
#	var path2 = game.tmp_prefix_inside+"/repos/remote/"
#	helpers.careful_delete(path2)
#
#	game.global_shell.run("mkdir " + path2)
#	game.global_shell.cd(path2)
#	game.global_shell.run("git init")
#	game.global_shell.run("git config receive.denyCurrentBranch ignore")
#	$RepositoryRemote.path = path2
	
	redraw_all_cards()
	arrange_cards()

#func _update_repo():
#	$Repository.update_everything()
#	$RepositoryRemote.update_everything()
	
func draw_rand_card():
	var new_card = preload("res://card.tscn").instance()
	var card = cards[randi() % cards.size()]
	new_card.command = card.command
	new_card.arg_number = card.arg_number
	new_card.description = card.description
	add_child(new_card)
	arrange_cards()
	
func arrange_cards():
	var t = Timer.new()
	t.wait_time = 0.05
	add_child(t)
	t.start()
	yield(t, "timeout")
	
	var amount_cards = get_tree().get_nodes_in_group("cards").size()
	var total_angle = min(50, 45.0/7*amount_cards)
	var angle_between_cards = 0
	if amount_cards > 1:
		angle_between_cards = total_angle / (amount_cards-1)
		
	var current_angle = -total_angle/2
	for card in get_tree().get_nodes_in_group("cards"):
		var target_position = Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y + 1500)
		var target_rotation = current_angle
		var translation_vec = Vector2(0,-1500).rotated(current_angle/180.0*PI)
		target_position += translation_vec
		current_angle += angle_between_cards
		card._home_position = target_position
		
		var tween = Tween.new()
		tween.interpolate_property(card, "position", card.position, target_position, 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		tween.interpolate_property(card, "rotation_degrees", card.rotation_degrees, target_rotation, 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		add_child(tween)
		tween.start()
		
func redraw_all_cards():
	for card in get_tree().get_nodes_in_group("cards"):
		card.queue_free()
	for i in range(7):
		draw_rand_card()
	
