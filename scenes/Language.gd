extends MenuButton


func _ready():
	make_popup_menu() # generate items for popup menu
	get_popup().connect("id_pressed", self, "_on_item_pressed")
	check_current_items()


func make_popup_menu():
	for lang in game.languages.values():
		get_popup().add_check_item(lang)


func check_current_items():
	var items_count = get_popup().get_item_count()
	for i in range(items_count):
		var idx = get_popup().get_item_index(i)
		if get_popup().get_item_text(idx) == game.languages[game.os_lang]:
			get_popup().set_item_checked(idx, true)
		else:
			get_popup().set_item_checked(idx, false)


func _on_item_pressed(id):
	#get_popup().set_item_checked(id, true)
	var lang = get_popup().get_item_text(id)
	for key in game.languages.keys():
		var value = tr(game.languages[key])
		if value == lang:
			game.os_lang = key
#			game.levels_dir = "res://levels/" + key
	
	check_current_items()
	TranslationServer.set_locale(game.os_lang)
