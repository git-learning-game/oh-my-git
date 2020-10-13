extends Node2D

var cards = [
	{"command": 'git add .', "arg_number": 0},
	{"command": 'git checkout', "arg_number": 1},
	{"command": 'touch "file$RANDOM"', "arg_number": 0},
	{"command": 'git commit --allow-empty -m "$RANDOM"', "arg_number": 0},
	{"command": 'git checkout -b "$RANDOM"', "arg_number": 0},
	{"command": 'git merge', "arg_number": 1},
	{"command": 'git symbolic-ref HEAD', "arg_number": 1},
	{"command": 'git update-ref -d', "arg_number": 1},
	{"command": 'git reflog expire --expire=now --all; git prune', "arg_number": 0},
	{"command": 'git rebase', "arg_number": 1}
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
	
	redraw_all_cards()
	arrange_cards()

func _update_repo():
	$Repository.update_everything()
	
func draw_rand_card():
	var new_card = preload("res://card.tscn").instance()
	var card = cards[randi() % cards.size()]
	new_card.command = card.command
	new_card.arg_number = card.arg_number
	add_child(new_card)
	arrange_cards()
	
func arrange_cards():
	var t = Timer.new()
	t.wait_time = 0.05
	add_child(t)
	t.start()
	yield(t, "timeout")
	
	var amount_cards = get_tree().get_nodes_in_group("cards").size()
	var total_angle = 45.0/7*amount_cards
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
	
