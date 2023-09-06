extends Control

var card_store = {}
var cards
var card_radius = 1500

func _ready():
	load_card_store()
	#redraw_all_cards()
	arrange_cards()
	pass

func _process(_delta):
	if $Energy:
		$Energy.text = str(game.energy)

func load_card_store():
	card_store = {}
	var test_json_conv = JSON.new()
	test_json_conv.parse(helpers.read_file("res://resources/cards.json"))
	var cards_json = test_json_conv.data
	for card in cards_json:
		card_store[card["id"]] = card
	
func draw_rand_card():
	var deck = []
	
	for card in cards:
		deck.push_back(card)
	
	# We want a lot of commit and checkout cards!
	for _i in range(5):
		deck.push_back(cards[0])
		deck.push_back(cards[1])
	
	var card = deck[randi() % deck.size()]
	draw_card(card)

func draw_card(card):
	var new_card = preload("res://scenes/card.tscn").instantiate()
	
	new_card.id = card["id"]
	new_card.command = card["command"]
	new_card.description = card["description"]
	new_card.energy = 0 #card.energy
	new_card.position = Vector2(size.x, size.y*2)
	add_child(new_card)
	arrange_cards()
	
func draw(ids):
	for card in get_tree().get_nodes_in_group("cards"):
		card.queue_free()
		
	for id in ids:
		draw_card(card_store[id])
	
	arrange_cards()
	
	if ids.size() > 0:
		game.notify("These are your cards! Drag them to highlighted areas to play them!", self, "cards")
	
func arrange_cards():
	var t = Timer.new()
	t.wait_time = 0.05
	add_child(t)
	t.start()
	await t.timeout
	
	var amount_cards = get_tree().get_nodes_in_group("cards").size()
	var total_angle = min(35, 45.0/7*amount_cards)
	var angle_between_cards = 0
	if amount_cards > 1:
		angle_between_cards = total_angle / (amount_cards-1)
	else:
		total_angle = 0
		
	var current_angle = -total_angle/2
	for card in get_tree().get_nodes_in_group("cards"):
		var target_position = Vector2(size.x/2, size.y + card_radius)
		var target_rotation = current_angle
		var translation_vec = Vector2(0,-card_radius).rotated(current_angle/180.0*PI)
		target_position += translation_vec
		current_angle += angle_between_cards
		card._home_position = target_position
		card._home_rotation = target_rotation
		
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", target_position, 0.5)
		tween.tween_property(card, "rotation_degrees", target_rotation, 0.5)
		
func redraw_all_cards():
	game.energy = 5
	
	for card in get_tree().get_nodes_in_group("cards"):
		card.queue_free()

	for card in card_store:
		draw_card(card_store[card])
	
	arrange_cards()

func add_card(command):
	draw_card({"command": command, "description": "", "arg_number": 0, "energy": 0})
